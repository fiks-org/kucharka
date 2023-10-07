##
#
# Knowledge template tasks
#
# Tomáš Kalvoda, FIT CTU, 2021-2022
# Matěj Frnka, FIT CTU, 2022
#
# See README.md
#

require 'rake'
require 'woowoo'
require 'json'
require 'open3'
require 'webrick'

IGNORED_REFERENCES = %w[footnote].freeze

MINDMAP_NAME = "mindmap".freeze
DOCUMENT_NAME = "document".freeze
MINDMAP_WOBJECTS = "parse_types".freeze

GRAPH_PY_FILE = "graph.py"
GRAPH_OUTPUT_FILE = "graph.json"
SOURCES_FOLDER = "src"

#
# Helper methods
#

def tic
  Process.clock_gettime(Process::CLOCK_MONOTONIC)
end

def toc
  Process.clock_gettime(Process::CLOCK_MONOTONIC)
end

#
# Find all interesting WObjects (WooWoo::Node) in the document.
#
def filter_wobjects(document, wobjects)
  output = {}

  document.spine.top_sections.each do |section|
    output.merge!(inspect_section(section, wobjects))
  end

  output
end

#
# Find all interesting WObjects (WooWoo::Node) in the section.
#
def inspect_section(section, wobjects)
  output = {}

  section.content.each do |object|
    output[object.label] = object if wobjects.include?(object.identifier)
  end

  section.children.each do |subsection|
    output.merge!(inspect_section(subsection, wobjects))
  end

  output
end

#
# Search children of the node for references _to other_ nodes.
#
def gather_references(node, ignore = true)
  output = []
  if IGNORED_REFERENCES.include?(node.identifier) && ignore
    return output;
  elsif node.identifier == 'full_reference'
    output << node.pointer.to_s
  elsif node.identifier == 'reference'
    if node.modifier.to_s == '@'
      output << node.get_meta(node.pointer.to_i)['ref'].to_s
    else
      output << node.content.to_s
    end
  elsif node.content.is_a?(Array)
    node.content.each do |child|
      output += gather_references(child)
    end
  elsif node.identifier == 'text_stub'
    node.parse_text_stub.each do |child|
      output += gather_references(child)
    end
  end

  return output
end

#
# Attempt to find a Proof of the given node among a few nodes
# just after this node.
#
def find_proof(node, search_offset = 2)
  if node.identifier == 'Proof'
    return nil # Cannot find proof of proof
  end
  node_idx = node.section.content.index(node)
  search_offset.times do |offset|
    idx = node_idx + offset + 1
    if idx < node.section.content.length
      next_node = node.section.content[idx]
      return next_node if next_node.identifier == 'Proof'
    end
  end

  return nil
end

#
# Raw text.
#
def content_to_text(content)
  if content.is_a?(WooWoo::Node)
    return content.r(content)
  elsif content.is_a?(Array)
    return content.map { |x| content_to_text(x) }.join("\n\n")
  else
    puts content.inspect
    raise 'Unexpected content!'
  end
end

#
# Find out document parts the given node belongs to.
#
def infer_document_parts(node)
  if node.section.identifier == 'Chapter'
    { chapter: node.section.label }
  elsif node.section.identifier == 'Section'
    { section: node.section.label, chapter: node.section.parent.label }
  else
    {
      subsection: node.section.label,
      section: node.section.parent.label,
      chapter: node.section.parent.parent.label
    }
  end
end

def get_help()
  return "EXAMPLE:
...
#{MINDMAP_NAME}:
  textbook_url: https://courses.fit.cvut.cz/BI-MA1/@master/textbook
  #{MINDMAP_WOBJECTS}:
    - Definition
    - Theorem
    - Lemma
    - Corollary
    - Proposition
..."
end

def get_builder
  template = WooWoo::Template.new('fit-knowledge')
  WooWoo::Builder.new(template)
end

#
# This function UNFORTUNATELY HAS TO BE COPIED FROM helpers.rb. There is no simple way to include functions from helpers.rb
# Apply micro-typographical transformations:
#
#  * Add non-breakable spaces after single character prepositions.
#  * Three dots are converted to a proper ellipsis.
#  * Converts a custom non-breakable space to the HTML entity.
#
# @param text [String]
#
def polish_text(text)
  # add non-breakable space after single character prepositions.
  text = text.gsub(/((\A|\s|\()+[AIKOUVSZaikouvsz])\s+/, '\1 ')
  text.gsub!('---', '—')
  text.gsub!('--', '–')
  text.gsub!('...', '…')
  text.gsub!('~', ' ')
  text.gsub!('\-', '&shy;')

  text
end

#
# Tasks
#

namespace :fitknowledge do
  desc 'Check out the document spine.'
  task :spine do
    builder = get_builder

    document = builder.document
    document.create_spine!
    document.spine.inspect_sections
  end

  desc 'Build the knowledge map and run all jobs.'
  task :build do
    builder = get_builder
    document = builder.document
    if !builder.raw_woofile.key?(MINDMAP_NAME) \
    || !builder.raw_woofile[MINDMAP_NAME].is_a?(Hash) \
    || !builder.raw_woofile[MINDMAP_NAME].key?(MINDMAP_WOBJECTS) \
    || !builder.raw_woofile[MINDMAP_NAME][MINDMAP_WOBJECTS].is_a?(Array)
      puts "Invalid Woofile"
      puts get_help
      exit 2
    end
    to_parse = builder.raw_woofile[MINDMAP_NAME][MINDMAP_WOBJECTS]
    print 'Creating spine...'
    t1 = tic
    document.create_spine!
    t2 = toc
    puts "  (#{format('%.3f', t2 - t1)}s)."

    print 'Digesting blobs...'
    t1 = tic
    document.digest_blobs!
    t2 = toc
    puts " (#{format('%.3f', t2 - t1)}s)."

    print 'Digesting text...'
    t1 = tic
    document.digest_text_stubs!
    t2 = toc
    puts "  (#{format('%.2f', t2 - t1)}s)."

    puts '---'
    puts 'Counters inspection:'
    puts WooWoo::Node.running_counters.inspect
    puts '---'

    print 'Searching for interesting wobjects...'
    t1 = tic
    wobjects = filter_wobjects(document, to_parse)
    t2 = toc
    puts " (#{format('%.3f', t2 - t1)}s)."

    data = {}
    wobjects.each do |label, wobject|
      data[label] = {
        type: wobject.identifier.to_s,
        label: label.to_s,
        title: polish_text(wobject.meta['title'].to_s),
        filename: wobject.section.filename.to_s,
        line: wobject.line,
        hash: wobject.hash,
        points_to: [],
        referenced_by: [],
        required_in_proof_of: [],
        proof_requires: [],
        content: content_to_text(wobject.content)
      }.merge(infer_document_parts(wobject))
    end
    puts "Number of interesting labels found: #{wobjects.length}"

    puts 'Gathering references to other objects...'
    wobjects.each do |label, wobject|
      gather_references(wobject).each do |lbl|
        if data.key?(lbl)
          points_to = data.dig(label, :points_to)
          points_to << lbl unless points_to.include?(lbl)
          referenced_by = data.dig(lbl, :referenced_by)
          referenced_by << label unless referenced_by.include?(label)
        end
      end

      # handle proofs
      proof = find_proof(wobject)
      next unless proof
      gather_references(proof, false).each do |lbl|
        if data.key?(lbl)
          proof_requires = data.dig(label, :proof_requires)
          proof_requires << lbl unless proof_requires.include?(lbl)
          required_in_proof_of = data.dig(lbl, :required_in_proof_of)
          required_in_proof_of << label unless required_in_proof_of.include?(label)
        end
      end
    end

    # Delete nodes with no references to make data cleaner
    data.delete_if { |label, entry| entry[:points_to].length == 0 and entry[:referenced_by].length == 0 }
    data.each { |label, entry| entry[:points_to].delete_if { |val| val == "" } }

    #
    # Save data to disk
    #

    puts 'Creating directories...'
    builder.create_directories!

    puts 'Rendering output file...'
    payload = {
      title: document.title,
      code: builder.document_config['code'],
      timestamp: Time.now,
      meta: builder.raw_woofile.slice(MINDMAP_NAME, DOCUMENT_NAME),
      data: data.values
    }
    File.open(File.join(builder.template_build_dir, "#{builder.output_file}.json"), "w:UTF-8") do |f|
      f.write(JSON.pretty_generate(payload))
    end
  end

  desc 'Build the knowledge map, run all jobs and generate a graph.'
  task :graph => [:build] do
    builder = get_builder
    output_file = File.join(builder.template_build_dir, "#{builder.output_file}.json")
    destination_file = File.join(builder.template_build_dir, SOURCES_FOLDER, GRAPH_OUTPUT_FILE)
    print 'Generating graph...'
    t1 = tic
    FileUtils.cp_r(File.join(__dir__, "src/"), builder.template_build_dir)
    executable_path = File.join(__dir__, GRAPH_PY_FILE)
    stdout, stderr, status = Open3.capture3("python", executable_path, output_file, destination_file)
    t2 = toc
    puts " (#{format('%.3f', t2 - t1)}s)."
    if stdout != ""
      puts stdout
    end
    if stderr != ""
      puts stderr
    end
  end

  desc 'Run a web server and serve the page.'
  task :serve do
    builder = get_builder
    src_root = File.join(builder.template_build_dir, SOURCES_FOLDER)

    puts 'Running a local web server, navigate your browser to http://localhost:8000.'
    server = WEBrick::HTTPServer.new Port: 8000, DocumentRoot: src_root
    server.start
  end
end
