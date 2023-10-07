#
# LaTeX template tasks
#

require 'rake'
require 'woowoo'
require 'fileutils'

#
# Helpers
#

def tic
  Process.clock_gettime(Process::CLOCK_MONOTONIC)
end

def toc
  Process.clock_gettime(Process::CLOCK_MONOTONIC)
end

#
# Tasks
#

namespace :fitpdf do
  desc 'Check out the document spine.'
  task :spine do
    template = WooWoo::Template.new('fit-pdf')
    builder = WooWoo::Builder.new(template)

    document = builder.document
    document.create_spine!
    document.spine.inspect_sections
  end

  desc 'Build the LaTeX document and run all jobs.'
  task :build do
    template = WooWoo::Template.new('fit-pdf')
    builder  = WooWoo::Builder.new(template)

    #
    # Create the document
    #

    document = builder.document
    print 'Creating spine...'
    t1 = tic
    document.create_spine!
    t2 = toc
    puts "  (#{format('%.1f', t2 - t1)}s)."

    print 'Digesting blobs...'
    t1 = tic
    document.digest_blobs!
    t2 = toc
    puts " (#{format('%.1f', t2 - t1)}s)."

    print 'Digesting text...'
    t1 = tic
    document.digest_text_stubs!
    t2 = toc
    puts "  (#{format('%.1f', t2 - t1)}s)."

    #
    # Render the LaTeX document
    #

    puts 'Creating directories...'
    builder.create_directories!

    puts 'Rendering output file...'
    File.write(
      File.join(builder.template_build_dir, "#{builder.output_file}.tex"),
      template.render(document)
    )

    #
    # Run Jobs
    #

    puts 'Running jobs...'
    builder.jobs.each do |job|
      print '.'
      job.process!
    end

    puts 'Done!'
  end

  desc 'Run pdflatex and friends.'
  task :pdf do
    template = WooWoo::Template.new('fit-pdf')
    builder  = WooWoo::Builder.new(template)

    # Copy logo
    FileUtils.copy('figures/logo.pdf', File.join(builder.template_build_dir, 'figures', 'logo.pdf'))

    if builder.document.bibliography.bibtex_file
      # Copy bibliography file
      FileUtils.copy(builder.document.bibliography.bibtex_file, File.join(builder.template_build_dir, builder.document.bibliography.bibtex_file))
    end

    Dir.chdir(builder.template_build_dir) do
      sh "pdflatex -shell-escape -interaction=nonstopmode #{builder.output_file}"
      sh "bibtex #{builder.output_file}" if builder.document.bibliography.bibtex_file
      sh "makeindex #{builder.output_file}"
      sh "pdflatex -shell-escape -interaction=nonstopmode #{builder.output_file}"
      sh "pdflatex -shell-escape -interaction=nonstopmode #{builder.output_file}"
    end
  end
end


# config     = YAML.load_file('Woofile')
# src_file   = Rake::FileList.new(config['main_file']).first
# latex_file = File.join(config['builder']['build_dir'], 'latex', src_file.ext('latex'))
# pdf_file   = File.join(config['builder']['build_dir'], 'latex', src_file.ext('pdf'))

# task latex: latex_file
# task pdf: pdf_file

# file latex_file => src_file do |t|
#   builder = WooWoo::Builder.new 'latex'
#   time_of_start = Time.now

#   tree = builder.build_tree
#   time_tree = Time.now

#   print 'LaTeX'
#   $stdout.flush

#   File.open(latex_file, 'w') do |f|
#     f.write WooWoo::Template.render(tree)
#   end
#   time_latex = Time.now

#   print 'Jobs'

#   builder.run_jobs
#   time_jobs = Time.now

#   puts "Building the tree: #{time_tree - time_of_start}"
#   puts "Rendering LaTeX:   #{time_latex - time_tree}"
#   puts "Finishing jobs:    #{time_jobs - time_latex}"
#   puts 'Done!'
# end

# file pdf_file => latex_file do |t|
#   builder = WooWoo::Builder.new 'latex'

#   unless WooWoo::Builder.bibtex_file.nil?
#     sh "cp #{WooWoo::Builder.bibtex_file} #{File.join(config['builder']['build_dir'], 'latex', WooWoo::Builder.bibtex_file)}"
#   end

#   Dir.chdir File.join(config['builder']['build_dir'], 'latex')

#   pp "Running LaTeX for the first time\n", :green
#   sh "pdflatex -shell-escape #{src_file.ext('latex')}"

#   pp "Running makeindex\n", :green
#   sh "makeindex #{src_file.ext('idx')}"

#   unless WooWoo::Builder.bibliography.nil?
#     pp "Running bibtex\n", :green
#     sh "bibtex #{src_file.ext('')}"
#   end

#   pp "Running LaTeX for the second time\n", :green
#   sh "pdflatex -shell-escape #{src_file.ext('latex')}"

#   pp "Running LaTeX for the third time\n", :green
#   sh "pdflatex -shell-escape #{src_file.ext('latex')}"
# end
