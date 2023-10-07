#
# HTML template tasks
#

require 'rake'
require 'woowoo'
require 'fileutils'
require 'webrick'

BOOTSTRAP_URL = 'https://github.com/twbs/bootstrap/releases/download/v5.1.0/bootstrap-5.1.0-dist.zip'.freeze
BOOTSTRAP_DARKLY_URL = 'https://bootswatch.com/5/darkly/bootstrap.min.css'.freeze
FONTAWESOME_URL = 'https://use.fontawesome.com/releases/v5.15.4/fontawesome-free-5.15.4-web.zip'.freeze
ANCHORJS_URL = 'https://github.com/bryanbraun/anchorjs/archive/refs/tags/4.3.1.zip'.freeze
JQUERY_URL = 'https://code.jquery.com/jquery-3.6.0.min.js'.freeze
PSEUDOCODE_JS_URL = 'https://github.com/SaswatPadhi/pseudocode.js/releases/download/v2.2.0/pseudocode.min.js'
PSEUDOCODE_CSS_URL = 'https://github.com/SaswatPadhi/pseudocode.js/releases/download/v2.2.0/pseudocode.min.css'

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

namespace :fithtml do
  desc 'Check out the document spine.'
  task :spine do
    template = WooWoo::Template.new('fit-html')
    builder = WooWoo::Builder.new(template)

    document = builder.document
    document.create_spine!
    document.spine.inspect_sections
  end

  desc 'Install CSS/JS dependencies and icons.'
  task :assets do
    template = WooWoo::Template.new('fit-html')
    builder  = WooWoo::Builder.new(template)

    puts 'Creating directories...'
    builder.create_directories!

    Dir.chdir(builder.template_build_dir) do
      puts 'Installing Bootstrap...'
      sh "wget #{BOOTSTRAP_URL} -O bootstrap.zip"
      sh 'unzip bootstrap.zip'
      sh 'rm bootstrap.zip'

      bootstrap_dir = Dir['bootstrap*'].first
      sh "cp -r #{bootstrap_dir}/* ./"
      sh "rm -rf #{bootstrap_dir}"

      # donwload Bootstrap Darkly theme
      sh "wget #{BOOTSTRAP_DARKLY_URL} -O bootstrap-darkly.min.css"
      sh 'mv bootstrap-darkly.min.css css/'

      # download and unpack Anchor
      sh "wget #{ANCHORJS_URL} -O anchor.zip"
      sh 'unzip anchor.zip'
      sh 'rm anchor.zip'

      anchor_dir = Dir['anchorjs*'].first
      sh "cp -r #{anchor_dir}/anchor.min.js ./js/"
      sh "rm -rf #{anchor_dir}"

      # download and unpack Fontawesome
      sh "wget #{FONTAWESOME_URL} -O fa.zip"
      sh 'unzip fa.zip'
      sh 'rm fa.zip'

      fa_dir = Dir['fontawesome*'].first
      sh "cp -r #{fa_dir}/css/all.min.css ./css/"
      sh "cp -r #{fa_dir}/webfonts ./"
      sh "rm -rf #{fa_dir}"

      # download jquery
      sh "wget #{JQUERY_URL} -O jquery.min.js"
      sh 'mv jquery.min.js ./js/'

      # download Pseudocode.js
      sh "wget #{PSEUDOCODE_JS_URL} -O ./js/pseudocode.min.js"
      sh "wget #{PSEUDOCODE_CSS_URL} -O ./css/pseudocode.min.css"
    end

    puts 'Copying custom template CSS and JS stuff and hacks...'
    sh "cp #{File.join('templates', 'fit-html', 'css', '*')} #{File.join(builder.template_build_dir, 'css')}/"
    sh "cp #{File.join('templates', 'fit-html', 'js', '*')} #{File.join(builder.template_build_dir, 'js')}/"

    puts 'Copying favicon.ico...'
    sh "cp figures/favicon.ico #{builder.template_build_dir}/"

    puts 'Copying logo...'
    FileUtils.copy('figures/logo.svg', File.join(builder.template_build_dir, 'logo.svg'))
  end

  desc 'Build the HTML document and run all jobs.'
  task :build do
    template = WooWoo::Template.new('fit-html')
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
    # Render the HTML pages
    #

    puts 'Creating directories...'
    builder.create_directories!

    puts 'Rendering the landing page...'
    File.open(File.join(builder.template_build_dir, 'index.html'), 'w') do |f|
      f.write template.render(document)
    end

    puts 'Rendering chapters and sections...'
    document.spine.top_sections.each do |chapter|
      print "  => #{chapter.numeric_label}: #{chapter.title}..."

      t1 = tic

      File.open(File.join(builder.template_build_dir, "#{chapter.label}.html"), 'w') do |f|
        f.write template.render(chapter)
      end

      chapter.children.each do |section|
        File.open(File.join(builder.template_build_dir, "#{section.label}.html"), 'w') do |f|
          f.write template.render(section)
        end
      end

      t2 = toc

      puts "(#{format('%.2f', t2 - t1)}s)."
    end

    puts 'Rendering references...'
    File.open(File.join(builder.template_build_dir, 'references.html'), 'w') do |f|
      f.write template.render_partial('_references', document.get_binding)
    end

    puts 'Building index...'
    document.index.digest_index!
    puts 'Rendering index...'
    File.open(File.join(builder.template_build_dir, 'index_page.html'), 'w') do |f|
      f.write template.render_partial('_index', document.get_binding)
    end

    #
    # Run Jobs
    #

    print 'Running jobs...'
    t1 = tic
    builder.jobs.each do |job|
      print '.'
      job.process!
    end
    t2 = toc
    puts "(#{format('%.2f', t2 - t1)}s)."
  end

  desc 'Run a web server and serve the page.'
  task :serve do
    template = WooWoo::Template.new('fit-html')
    builder  = WooWoo::Builder.new(template)
    puts "Serving files from #{builder.template_build_dir}.\nNavigate your browser to http://localhost:8000."
    server = WEBrick::HTTPServer.new Port: 8000, DocumentRoot: builder.template_build_dir
    server.start
  end
end

# task :build do
#   builder = WooWoo::Builder.new 'html'

#   tree = builder.build_tree

#   WooWoo::Builder.build_label_index

#   print 'HTML'
#   $stdout.flush

#   # main index file
#   File.open(File.join(builder.build_dir, 'html', 'index.html'), 'w') do |f|
#     f.write WooWoo::Template.render(tree)
#   end

#   # chapters
#   WooWoo::Divider.top_level.each do |chap|
#     print 'Chapter'
#     $stdout.flush

#     File.open(File.join(builder.build_dir, 'html', chap.meta['label'] + '.html'), 'w') do |f|
#       f.write WooWoo::Template.render(chap)
#     end

#     chap.subdividers.each do |sec|
#       print 'Section'
#       $stdout.flush
      
#       File.open(File.join(builder.build_dir, 'html', sec.meta['label'] + '.html'), 'w') do |f|
#         f.write WooWoo::Template.render(sec)
#       end
#     end
#   end

#   print 'Index'
#   File.open(File.join(builder.build_dir, 'html', 'index_page.html'), 'w') do |f|
#     f.write WooWoo::Template.render('_index', tree.get_binding)
#   end

#   print 'References'
#   File.open(File.join(builder.build_dir, 'html', 'references.html'), 'w') do |f|
#     f.write WooWoo::Template.render('_references', tree.get_binding)
#   end

#   print 'Jobs'

#   builder.run_jobs

#   puts 'Done!'
# end

#
# Merge somewhere else...
#

# html:

#   anchorjs_src: https://github.com/bryanbraun/anchorjs/archive/3.2.2.zip
#   fontawesome_src: https://use.fontawesome.com/releases/v5.2.0/fontawesome-free-5.2.0-web.zip
