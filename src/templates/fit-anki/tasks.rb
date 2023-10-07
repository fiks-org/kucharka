#
# HTML template tasks
#

require 'rake'
require 'woowoo'
require 'fileutils'

#
# Helpers
#

ANKI_WOBJECTS = %w[Definition Theorem Lemma Corollary Proposition Question]

def tic
  Process.clock_gettime(Process::CLOCK_MONOTONIC)
end

def toc
  Process.clock_gettime(Process::CLOCK_MONOTONIC)
end

#
# Find all interesting WObjects (WooWoo::Node) in the section.
#
def inspect_chapter(section)
  output = {}

  section.content.each do |object|
    if ANKI_WOBJECTS.include?(object.identifier)
      output[object.label] = object
    end
  end

  section.children.each do |subsection|
    output.merge!(inspect_chapter(subsection))
  end

  output
end

#
# Fix custom LaTeX macros.
#
def anki_sanitize(text)
  text = text.gsub(/\\N(?=([^\w]|$))/, '\mathbb{N}')
  text = text.gsub(/\\R(?=([^\w]|$))/, '\mathbb{R}')
  text = text.gsub(/\\Z(?=([^\w]|$))/, '\mathbb{z}')
  text = text.gsub(/\\Q(?=([^\w]|$))/, '\mathbb{Q}')
  text = text.gsub(/\\C(?=([^\w]|$))/, '\mathbb{C}')
  text = text.gsub(/\\e(?=([^\w]|$))/, '\mathrm{e}')
  text = text.gsub(/\\ii(?=([^\w]|$))/, '\mathrm{i}')
  text = text.gsub(/\\Re(?=([^\w]|$))/, '\mathrm{Re}\,')
  text = text.gsub(/\\Im(?=([^\w]|$))/, '\mathrm{Im}\,')
  text = text.gsub(/\\tg(?=([^\w]|$))/, '\mathrm{tg}')
  text = text.gsub(/\\ctg(?=([^\w]|$))/, '\mathrm{cotg}')
  text = text.gsub(/\\cotg(?=([^\w]|$))/, '\mathrm{cotg}')
  text = text.gsub(/\\arctg(?=([^\w]|$))/, '\mathrm{arctg}')
  text = text.gsub(/\\arcctg(?=([^\w]|$))/, '\mathrm{arccotg}')
  text = text.gsub(/\\ceq(?=([^\w]|$))/, ':=')
  text = text.gsub(/\\veps(?=([^\w]|$))/, '\varepsilon')
  text = text.gsub(/\\sgn(?=([^\w]|$))/, '\mathrm{sgn}')
  text = text.gsub(/\\dt(?=([^\w]|$))/, '\,\mathrm{d}t')
  text = text.gsub(/\\dx(?=([^\w]|$))/, '\,\mathrm{d}x')
  text = text.gsub(/\\mA(?=([^\w]|$))/, '\mathbf{A}')
  text = text.gsub(/\\mB(?=([^\w]|$))/, '\mathbf{B}')
  text = text.gsub(/\\mC(?=([^\w]|$))/, '\mathbf{C}')
  text = text.gsub(/\\mD(?=([^\w]|$))/, '\mathbf{D}')
  text = text.gsub(/\\mE(?=([^\w]|$))/, '\mathbf{E}')
  text = text.gsub(/\\mP(?=([^\w]|$))/, '\mathbf{P}')
  text = text.gsub(/\\mQ(?=([^\w]|$))/, '\mathbf{Q}')
  text = text.gsub(/\\mX(?=([^\w]|$))/, '\mathbf{X}')
  text = text.gsub(/\\vx(?=([^\w]|$))/, '\mathbf{x}')
  text = text.gsub(/\\vy(?=([^\w]|$))/, '\mathbf{y}')
  text = text.gsub(/\\vz(?=([^\w]|$))/, '\mathbf{z}')
  text = text.gsub(/\\va(?=([^\w]|$))/, '\mathbf{a}')
  text = text.gsub(/\\vb(?=([^\w]|$))/, '\mathbf{b}')
  text = text.gsub(/\\vc(?=([^\w]|$))/, '\mathbf{c}')
  text = text.gsub(/\\ve(?=([^\w]|$))/, '\mathbf{e}')
  text = text.gsub(/\\vu(?=([^\w]|$))/, '\mathbf{u}')
  text = text.gsub(/\\vv(?=([^\w]|$))/, '\mathbf{v}')
  text = text.gsub(/\\vw(?=([^\w]|$))/, '\mathbf{w}')
  text = text.gsub(/\\XX(?=([^\w]|$))/, '\mathcal{X}')
  text = text.gsub(/\\YY(?=([^\w]|$))/, '\mathcal{Y}')
  text = text.gsub(/\\EE(?=([^\w]|$))/, '\mathcal{E}')
  text = text.gsub(/\\ssubset(?=([^\w]|$))/, '\subset\subset')

  text
end

#
# Tasks
#

namespace :fitanki do
  desc 'Check out the document spine.'
  task :spine do
    template = WooWoo::Template.new('fit-anki')
    builder = WooWoo::Builder.new(template)

    document = builder.document
    document.create_spine!
    document.spine.inspect_sections
  end

  desc 'Build Anki cards.'
  task :build do
    template = WooWoo::Template.new('fit-anki')
    builder  = WooWoo::Builder.new(template)

    #
    # Create the document
    #

    document = builder.document
    print 'Creating spine...'
    t1 = tic
    document.create_spine!
    t2 = toc
    puts "  (#{format('%.2f', t2 - t1)}s)."

    print 'Digesting blobs...'
    t1 = tic
    document.digest_blobs!
    t2 = toc
    puts " (#{format('%.2f', t2 - t1)}s)."

    print 'Digesting text...'
    t1 = tic
    document.digest_text_stubs!
    t2 = toc
    puts "  (#{format('%.2f', t2 - t1)}s)."

    print 'Indexing labels...'
    t1 = tic
    document.spine.register_node_labels!
    t2 = toc
    puts " (#{format('%.2f', t2 - t1)}s)."
    puts "  => There are #{document.index.labels.length} labels."

    #
    # Render Anki cards
    #

    puts 'Creating directories...'
    builder.create_directories!

    puts 'Rendering decks for each chapter...'
    document.spine.top_sections.each do |chapter|
      print "  => #{chapter.numeric_label}: #{chapter.title}..."

      t1 = tic

      wobjects = inspect_chapter(chapter)

      print " #{wobjects.length} cards "

      File.open(File.join(builder.template_build_dir, "#{document.meta['code']}-#{chapter.label}.csv"), 'w') do |f|
        wobjects.each do |label, wobject|
          next if wobject.skip_node_rendering?(wobject)

          f.write anki_sanitize(template.render(wobject)) + ";\"#{document.meta['code']}::#{chapter.label} #{wobject.identifier}\"\n"
        end
      end

      t2 = toc

      puts "(#{format('%.2f', t2 - t1)}s)."
    end
  end
end

