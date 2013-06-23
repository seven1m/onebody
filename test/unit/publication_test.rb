require_relative '../test_helper'

class PublicationTest < ActiveSupport::TestCase

  should "have a pseudo filename" do
    @publication = Publication.forge(:name => 'foo')
    assert_equal 'foo.pdf', @publication.pseudo_file_name
  end

  should "use the id for the filename as a fallback" do
    @publication = Publication.forge(:name => '-')
    assert_equal "#{@publication.id}.pdf", @publication.pseudo_file_name
  end

end
