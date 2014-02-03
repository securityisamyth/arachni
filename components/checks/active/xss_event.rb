=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

# It injects a string and checks if it appears inside an event attribute of any HTML tag.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.5
#
# @see http://cwe.mitre.org/data/definitions/79.html
# @see http://ha.ckers.org/xss.html
# @see http://secunia.com/advisories/9716/
class Arachni::Checks::XSSEvent < Arachni::Check::Base

    EVENT_ATTRS = [
        'onload',
        'onunload',
        'onblur',
        'onchange',
        'onfocus',
        'onreset',
        'onselect',
        'onsubmit',
        'onabort',
        'onkeydown',
        'onkeypress',
        'onkeyup',
        'onclick',
        'ondblclick',
        'onmousedown',
        'onmousemove',
        'onmouseout',
        'onmouseover',
        'onmouseup'
    ]

    def self.strings
        @strings ||= [
            ";arachni_xss_in_element_event=#{seed}//",
            "\";arachni_xss_in_element_event=#{seed}//",
            "';arachni_xss_in_element_event=#{seed}//"
        ]
    end

    def self.options
        @options ||= { format: [ Format::APPEND ] }
    end

    def run
        audit self.class.strings, self.class.options, &method(:check_and_log)
    end

    def check_and_log( response, element )
        return if element.seed.to_s.empty? ||
            !response.body.to_s.include?( element.seed )

        doc = Nokogiri::HTML( response.body )

        EVENT_ATTRS.each do |attr|
            doc.xpath( "//*[@#{attr}]" ).each do |elem|
                next if !elem.attributes[attr].to_s.include?( element.seed )
                log( { vector: element }, response )
            end
        end
    end

    def self.info
        {
            name:        'XSS in HTML element event attribute',
            description: %q{Cross-Site Scripting in event tag of HTML element.},
            elements:    [Element::Form, Element::Link, Element::Cookie, Element::Header],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            version:     '0.1.5',
            targets:     %w(Generic),

            issue:       {
                name:            %q{Cross-Site Scripting in event tag of HTML element},
                description:     %q{Unvalidated user input is being embedded inside
    an HMTL event element such as "onmouseover".
    This makes Cross-Site Scripting attacks much easier to mount since the user input
    lands in code waiting to be executed.},
                references:  {
                    'ha.ckers' => 'http://ha.ckers.org/xss.html',
                    'Secunia'  => 'http://secunia.com/advisories/9716/'
                },
                tags:            %w(xss event injection dom attribute),
                cwe:             79,
                severity:        Severity::HIGH,
                remedy_guidance: 'User inputs must be validated and filtered
    before being included in executable code or not be included at all.',
            }

        }
    end

end
