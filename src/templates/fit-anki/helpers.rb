
module WooWoo
  module Helpers

    TEMPLATE_SIGNATURE = 'FIT Anki Template v0.1.0'.freeze

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
  end
end
