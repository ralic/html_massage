# -*- encoding: utf-8 -*-

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'html_massage'))

describe HtmlMassager::HtmlMassage do

  include HtmlMassager

  describe ".html" do
    it 'Should massage and output HTML' do
      html = "<html><body><div>This is some great content!</div></body></html>"
      HtmlMassage.html(html).should == "<div>This is some great content!</div>"
    end

    it 'should remove HTML "doctype"' do
      html = '
        <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
        <html xmlns="http://www.w3.org/1999/xhtml">
        <body>
          <p>foobar</p>
        </body>
        </html>
        '
      HtmlMassage.html(html).strip.should == "<p>foobar</p>"
    end

  end

  describe ".text" do
    it 'Should massage and output text' do
      html = "<html><body><div>This is some great content!</div></body></html>"
      HtmlMassage.text(html).strip.should == "This is some great content!"
    end

    it 'should convert an HTML sample as expected' do
      html = "
        <html><body>
        <h1>Title</h1>
        This is the body.
        Testing <a href='http://www.google.com/'>link to Google</a>.
        <p />
        Testing image <img src='/noimage.png'>.
        <br />
        The End.
        </body></html>
        "
      HtmlMassage.text(html).strip.should == "Title

        This is the body. Testing link to Google.

        Testing image .
        The End.
        ".strip.gsub(/^ +/, '')
    end

    it 'should play nice with UTF8 HTML source' do
      html = '
        <html>
        <head>
          <meta content="text/html; charset=utf-8" http-equiv="content-type" />
        </head>
        <body>
          Niq is a performer → Angry, arrogant, &amp; so admired.
        </body>
        </html>
        '
      HtmlMassage.text(html).strip.should == "Niq is a performer → Angry, arrogant, & so admired."
    end

    it 'should play nice with &nbsp;' do
      pending
      html = '&nbsp;&nbsp;&nbsp;'
      HtmlMassage.text(html).strip.should == "   "
    end
  end

  describe ".markdown" do
    it 'Should massage and output markdown' do
      html = "<html><body><div>This is some <i>great</i> content!</div></body></html>"
      massaged = HtmlMassage.markdown html
      massaged.strip.should == "This is some _great_ content!"
    end
  end

  describe "#massage!" do

    context 'invalid html' do
      [
        "<html><body>foobar</body>",
        "<html><body>foobar</html>",
        "<body>foobar</body></html>",
        "<html>foobar</body></html>",
      ].each do |broken_html|
        it "should return 'foobar' when given #{broken_html.inspect}" do
          HtmlMassage.new(broken_html).massage!.to_text.strip.should == "foobar"
        end
      end
    end

    pending 'should convert an HTML sample as expected'

    it 'should leave HTML entities intact' do
      pending 'improve ::Node.massage_html -- handling of html entities, utf8 chars'
      original = "This &ldquo;branching&rdquo; of creative works"
      massage = HtmlMassager::HtmlMassage.new( original )
      massage.massage!.should == original
    end
  end

  describe ".sanitize_html" do
    it 'should remove <style> tags and their contents' do
      html = %~<!-- Remix button --><br />
        <style type='text/css'>
            a.remix_on_wikinodes_tab {
            top: 25%; left: 0; width: 42px; height: 100px; color: #FFF; cursor:pointer; text-indent:-99999px; overflow:hidden; position: fixed; z-index: 99999; margin-left: -7px; background-image: url(http://www.openyourproject.org/images/remix_tab.png); _position: absolute; right: 0 !important; left: auto !important; margin-right: -7px !important; margin-left: auto !important; } a.remix_on_wikinodes_tab:hover { margin-left: -4px; margin-right: -4px !important; margin-left: auto !important;
          }
        </style>
        <p> <script type="text/javascript" language="javascript"> document.write( '<a style="background-color: #2a2a2a;" class="remix_on_wikinodes_tab" href="http://www.openyourproject.org/nodes/new?parent=' + window.location + '" title="Remix this content on WikiNodes -- creative collaboration designed to set you free" >Remix This</a>' ); </script> <noscript>Note: you can turn on Javascript to see the &#8216;Remix This&#8217; link.</noscript></p>
      ~
      html_massager = HtmlMassage.new( html )
      html_massager.sanitize!.should_not =~ /remix_on_wikinodes_tab/
    end

    it 'should remove <noscript> tags and their contents' do
      html = %{ <noscript>Note: you can turn on Javascript to see the 'Remix This' link. </noscript> }
      html_massager = HtmlMassage.new( html )
      html_massager.sanitize!.strip.should == ''
    end
  end

  describe '#absolutify_links' do
    it 'should work for absolute path links' do
      source_url = 'http://en.wikipedia.org/wiki/Singularity'
      original_html = '<a href="/wiki/Ray_Kurzweil">Ray</a>'
      html_massager = HtmlMassage.new( original_html )
      html_massager.absolutify_links!(source_url).should ==
          '<a href="http://en.wikipedia.org/wiki/Ray_Kurzweil">Ray</a>'
    end

    it 'should work for absolute path links (bugfix)' do
      source_url = 'http://p2pfoundation.net/NextNet'
      original_html = '<a href="/Ten_Principles_for_an_Autonomous_Internet" title="Ten Principles for an Autonomous Internet">Ten Principles for an Autonomous Internet</a>'
      html_massager = HtmlMassage.new( original_html )
      html_massager.absolutify_links!(source_url).should ==
          '<a href="http://p2pfoundation.net/Ten_Principles_for_an_Autonomous_Internet" title="Ten Principles for an Autonomous Internet">Ten Principles for an Autonomous Internet</a>'
    end

    it 'should work for relative links' do
      pending
      source_url = 'http://en.wikipedia.org/wiki/Singularity'
      original_html = '<a href="Ray_Kurzweil">Ray</a>'
      html_massager = HtmlMassage.new( original_html )
      html_massager.absolutify_links!(source_url).should ==
          '<a href="http://en.wikipedia.org/wiki/Ray_Kurzweil">Ray</a>'
    end

    it 'should work for relative links to a parent director' do
      source_url = 'http://en.wikipedia.org/wiki/Singularity'
      original_html = '<a href="../wiki/Ray_Kurzweil">Ray</a>'
      html_massager = HtmlMassage.new( original_html )
      html_massager.absolutify_links!(source_url).should ==
          '<a href="http://en.wikipedia.org/wiki/../wiki/Ray_Kurzweil">Ray</a>'
    end

    it 'should leave full URLs alone' do
      source_url = 'http://en.wikipedia.org/wiki/Singularity'
      original_html = '<a href="http://www.wired.com/wiredscience">wired science</a>'
      html_massager = HtmlMassage.new( original_html )
      html_massager.absolutify_links!(source_url).should == original_html
    end

    it 'should leave // style URLs alone' do
      source_url = 'http://en.wikipedia.org/wiki/Singularity'
      original_html = '<a href="//wired.com/wiredscience">wired science</a>'
      html_massager = HtmlMassage.new( original_html )
      html_massager.absolutify_links!(source_url).should == original_html
    end

    it 'should leave "jump links" alone' do
      source_url = 'http://en.wikipedia.org/wiki/Singularity'
      original_html = '<a href="#cite_1">1</a>'
      html_massager = HtmlMassage.new( original_html )
      html_massager.absolutify_links!(source_url).should == original_html
    end
  end

  describe '#absolutify_images!' do
    it 'should work for absolute path links' do
      source_url = 'http://enlightenedstructure.org/Home/'
      original_html = '<img src="/IMG/we-are.png" alt="" class="icon">'
      html_massager = HtmlMassage.new( original_html )
      html_massager.absolutify_images!(source_url).should ==
          '<img src="http://enlightenedstructure.org/IMG/we-are.png" alt="" class="icon">'
    end

    it 'should work for absolute path links (bugfix)' do
      source_url = 'http://www.realitysandwich.com/blog/daniel_pinchbeck'
      original_html = '<img src="/sites/realitysandwich.com/themes/zen/pinkreality/images/creative-commons-license.png" alt="Attribution-Noncommercial-Share Alike 3.0 Unported" title="" width="88" height="31">'
      html_massager = HtmlMassage.new( original_html )
      html_massager.absolutify_images!(source_url).should ==
          '<img src="http://www.realitysandwich.com/sites/realitysandwich.com/themes/zen/pinkreality/images/creative-commons-license.png" alt="Attribution-Noncommercial-Share Alike 3.0 Unported" title="" width="88" height="31">'
    end

    it 'should leave // style URLs alone' do
      source_url = 'http://en.wikipedia.org/wiki/List_of_communes_in_France_with_over_20,000_inhabitants_(2006_census)'
      original_html = '<img alt="" src="//upload.wikimedia.org/wikipedia/commons/thumb/f/f9/France-CIA_WFB_Map.png/220px-France-CIA_WFB_Map.png" width="220" height="235" class="thumbimage">'
      html_massager = HtmlMassage.new( original_html )
      html_massager.absolutify_images!(source_url).should == original_html
    end
  end

  describe '#tidy_tables!' do
    it 'should remove multiple newlines from tables' do
      HtmlMassage.new("<table><tr>\n<th>Chư\n\n\nYang Sin National Park</th>\n\n\n</tr></table>").tidy_tables!.should ==
        "<table><tr>\n<th>Chư\nYang Sin National Park</th>\n</tr></table>"
    end
  end

end
