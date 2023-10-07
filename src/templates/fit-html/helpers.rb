
module WooWoo
  module Helpers

    TEMPLATE_SIGNATURE = 'FIT HTML Template v0.2.3'.freeze

    #
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
      text.gsub!(/((\A|\s|\()+[AIKOUVSZaikouvsz])\s+/, '\1&nbsp;')
      text.gsub!('---', '&mdash;')
      text.gsub!('--', '&ndash;')
      text.gsub!('...', '&hellip;')
      text.gsub!('~', '&nbsp;')
      text.gsub!('\-', '&shy;')

      text
    end

    #
    # @param text [String]
    # @return
    #
    def sanitize_labels(text)
      encoding_options = {
        invalid:           :replace,  # Replace invalid byte sequences
        undef:             :replace,  # Replace anything not defined in ASCII
        replace:           '',        # Use a blank for those replacements
        universal_newline: true       # Always break lines with \n
      }

      text.encode(Encoding.find('ASCII'), encoding_options)
    end

    #
    #
    #
    # @param id1 [String] identifier of the first node
    # @param part1 [String] first rendered part
    # @param id2 [String] identifier of the second node
    # @param part2 [String] second rendered part
    #
    def glue_text_nodes(id1, part1, id2, part2)
      if ['cite', 'eqref', 'reference', 'full_reference'].include?(id2) && part1[-1] != '('
        '&nbsp;'
      elsif id2 == 'footnote' || part2.match?(/^[.,:;!?]/)
        ''
      elsif id1 == 'text_stub' && id2 == 'text_stub'
        "\n"
      elsif id1 == 'item' && id2 == 'item'
        ''
      elsif part1[-1] == '(' || part2[0] == ')'
        ''
      elsif (part1.length > 1 && part1.match?(/\s[AIKOUVSZaikouvsz]\z/)) || (part1.length == 1 && part1.match?(/[AIKOUVSZaikouvsz]/))
        '&nbsp;'
      elsif id1 == 'math' && part2.match?(/\A-\w/)
        ''
      else
        ' '
      end
    end

    #
    # Every node belongs to one of the following sections: Chapter, Section,
    # Subsection. If it belongs to Chapter or Section, return it. If it belongs
    # to a Subsection return the parent Section.
    #
    # @return [Section]
    #
    def Chapter_or_Section
      if %w[Chapter Section].include?(section.identifier)
        section
      else
        section.parent
      end
    end

    #
    # @return [Integer] parent chapter counter
    #
    def parent_chapter_counter
      target = section

      while target.identifier != 'Chapter'
        target = target.parent
      end

      target.counter
    end

    #
    # @return [String] node numeric label
    #
    def numeric_label
      parent_chapter_counter.to_s + '.' + section_counter.to_s
    end

    #
    #
    # @param lbl [String]
    # @return [String]
    #
    def link_to(lbl)
      object = document.index.labels[lbl]

      if object.nil?
        puts "Unknown label #{lbl}!"
        return ''
      elsif object.is_a?(Section) && %w[Chapter Section].include?(object.identifier)
        "#{object.label}.html"
      elsif object.is_a?(Section) && ('Subsection' == object.identifier)
        "#{object.parent.label}.html\##{object.label}"
      else
        "#{object.Chapter_or_Section.label}.html\##{lbl}"
      end
    end

    #
    #
    # @param lbl [String]
    # @return [String]
    #
    def numeric_label_of(lbl)
      object = document.index.labels[lbl]

      if object.nil?
        puts "Unknown label #{lbl}!"
        return ''
      else
        object.numeric_label
      end
    end

    # #
    # # Shortcuts...
    # #

    # #
    # # @return [String] the title of the document
    # #
    # def document_title
    #   WooWoo::Document.meta['title']
    # end

    # #
    # # @return [Array<Hash>] authors of the document. Each author can have
    # #                       associated `name`, `email` and `institute`.
    # #
    # def document_authors
    #   WooWoo::Document.meta['authors']
    # end

    # #
    # # @return [String] current time stamp
    # #
    # def timestamp
    #   Time.now.to_s
    # end

    # #
    # # HTML related
    # #

    # #
    # # Numbering
    # #
    # def divider_numbering(divider)
    #   if !WooWoo::Template.numbered_dividers.include?(divider.node_type)
    #     return ''
    #   else
    #     div = divider
    #     out = divider.counter.to_s

    #     until div.parent_divider.nil?
    #       div = div.parent_divider
    #       out = div.counter.to_s + '.' + out
    #     end

    #     return out
    #   end
    # end

    # #
    # # Numbering
    # #
    # def environment_numbering(environment)
    #   return '???' if environment.nil?

    #   out = environment.counter.to_s
    #   number_within = nil

    #   # is the environment numbered within specified divider?
    #   WooWoo::Template.counters.each do |c|
    #     if c['nodes'].include? environment.node_type
    #       number_within = c['within']
    #       break
    #     end
    #   end

    #   # if no, just return the number
    #   return out unless number_within

    #   # if so, let us find the divider
    #   div = environment.parent_divider

    #   while !div.nil? && div.node_type != number_within
    #     div = div.parent_divider
    #   end

    #   out = divider_numbering(div) + '.' + out if !div.nil?

    #   return out
    # end

    # #
    # #
    # #
    # def link_to(target)
    #   return 'target_not_found' if target.nil?

    #   out = 'TODO'

    #   if target.is_a? String
    #     element = WooWoo::Builder.get_element_labeled_with target
    #   else
    #     element = target
    #   end

    #   if element.is_a? WooWoo::Environment
    #     div = element.parent_divider
    #     div = div.parent_divider if div.node_type == 'Subsection'

    #     out = "#{div.label}.html\##{element.label}"
    #   elsif element.is_a? WooWoo::Divider
    #     div = element
        
    #     if div.node_type == 'Subsection'
    #       out = "#{div.parent_divider.label}.html\##{div.label}"
    #     else # it is Section or Chapter
    #       out = "#{div.label}.html"
    #     end
    #   elsif element.is_a? WooWoo::InlineBlock
    #     par = element.parent

    #     until [WooWoo::Environment, WooWoo::Block].include?(par.class) && !par.parent_divider.nil?
    #       par = par.parent
    #       return 'NA' if par.nil?
    #     end

    #     div = par.parent_divider
    #     div = div.parent_divider if div.node_type == 'Subsection'

    #     if element.has_meta? 'label'
    #       out = "#{div.label}.html\##{element.label}"
    #     else
    #       out = "#{div.label}.html\##{par.label}"
    #     end
    #   end

    #   out
    # end

    # def index_item_description(node)
    #   par = node.parent

    #   while par.class != WooWoo::Environment && par.parent != nil
    #     par = par.parent
    #   end

    #   if par.parent.nil?
    #     'text'
    #   elsif par.node_type == 'Definition'
    #     'definice'
    #   elsif par.node_type == 'Theorem'
    #     'věta'
    #   elsif par.node_type == 'Proof'
    #     'důkaz'
    #   else
    #     'text'
    #   end
    # end

    # def text_block_html(elements)
    #   out = ''

    #   elements.each_with_index do |element, i|
    #     if i == 0
    #       spacing = ''
    #     elsif element.node_type == 'footnote'
    #       spacing = ''
    #     elsif element.node_type == 'text' && element.content.start_with?('.', ',', ';', '!', '?', ':', ')', '-')
    #       spacing = ''
    #     elsif elements[i-1].node_type == 'text' && elements[i-1].content.end_with?('(')
    #       spacing = ''
    #     else
    #       spacing = ' '
    #     end

    #     if element.node_type == 'text'
    #       out += spacing + WooWoo::Template.render(element).gsub('--', '&ndash;').gsub('---', '&mdash').gsub('...', '&hellip;').gsub('~', '&nbsp;')
    #     else
    #       out += spacing + WooWoo::Template.render(element)
    #     end
    #   end

    #   out
    # end

    # def text_block_epub(elements)
    #   out = ''

    #   elements.each_with_index do |element, i|
    #     if i == 0
    #       spacing = ''
    #     elsif element.node_type == 'footnote'
    #       spacing = ''
    #     elsif element.node_type == 'text' && element.content.start_with?('.', ',', ';', '!', '?', ':', ')', '-')
    #       spacing = ''
    #     elsif elements[i-1].node_type == 'text' && elements[i-1].content.end_with?('(')
    #       spacing = ''
    #     else
    #       spacing = ' '
    #     end

    #     if element.node_type == 'text'
    #       # see https://www.w3.org/wiki/Common_HTML_entities_used_for_typography
    #       out += spacing + WooWoo::Template.render(element).gsub('--', '&#8211;').gsub('---', '&#8212;').gsub('...', '&#8230;').gsub('~', '&#160;')
    #     else
    #       out += spacing + WooWoo::Template.render(element)
    #     end
    #   end

    #   out
    # end
  end
end
