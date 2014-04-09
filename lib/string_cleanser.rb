module StringCleanser
  # Strips non-xml characters from the string.
  # These characters don't cause issues with Ruby, but they
  # crash Solr. These are discouraged in xml.
  # http://mysolr.com/tips/update-with-invalid-control-character-crashes-solr/
  # http://www.w3.org/TR/xml11/#charsets
  def strip_non_xml_chars(string)
    return nil unless string
    non_utf8_chars = %w( 00 01 02 03 04 05 06 07 08 0B 0C 0E 0F
                         10 11 12 13 14 15 16 17 18 19 1A 1B 1C
                         1D 1E 1F FFFE FFFF)
    delete_string = non_utf8_chars.inject(''){|memo, c| memo + c.to_i(16).chr}
    string.delete delete_string
  end
end