require 'saxon/item_type'
require 'saxon/processor'
require 'saxon/qname'
require 'bigdecimal'

module Saxon
  RSpec.describe ItemType do
    context "mapping Ruby types to xs:* types" do
      {
        ::String => S9API::ItemType::STRING,
        ::Array => S9API::ItemType::ANY_ARRAY
      }.each do |ruby_type, xsd_type|
        specify "Ruby type #{ruby_type} maps to #{xsd_type}" do
          expect(described_class.get_type(ruby_type).to_java).to be(xsd_type)
        end
      end

      specify "unmapped types raise an appropriate error" do
        expect {
          described_class.get_type(::Object)
        }.to raise_error(Saxon::ItemType::UnmappedRubyTypeError)
      end
    end

    context "mapping QNames using the xs: namespace" do
      let(:ns_uri) { 'http://www.w3.org/2001/XMLSchema' }

      {
        Saxon::QName.create({
          uri: 'http://www.w3.org/2001/XMLSchema', prefix: 'xs', local_name: 'string'
        }) => S9API::ItemType::STRING,
        Saxon::QName.create({
          uri: 'http://www.w3.org/2001/XMLSchema', prefix: 'xs', local_name: 'boolean'
        }) => S9API::ItemType::BOOLEAN
      }.each do |qname, xsd_type|
        specify "QName '#{qname}' maps to #{xsd_type}" do
          expect(described_class.get_type(qname).to_java).to be(xsd_type)
        end
      end

      specify "unmapped QNames raise an appropriate error" do
        expect {
          described_class.get_type(Saxon::QName.clark("{http://www.w3.org/2001/XMLSchema}fnord"))
        }.to raise_error(Saxon::ItemType::UnmappedXSDTypeNameError)
      end
    end

    context "mapping string QNames using the xs: namespace and string SequenceTypes" do
      {
        'xs:string' => S9API::ItemType::STRING,
        'xs:duration' => S9API::ItemType::DURATION,
        'node()' => S9API::ItemType::ANY_NODE
      }.each do |qname_str, xsd_type|
        specify "Ruby string '#{qname_str}' maps to #{xsd_type}" do
          expect(described_class.get_type(qname_str).to_java).to be(xsd_type)
        end
      end

      specify "unmapped type strings raise an appropriate error" do
        expect {
          described_class.get_type('xs:fnord')
        }.to raise_error(Saxon::ItemType::UnmappedXSDTypeNameError)
      end
    end

    specify "passing an existing ItemType instance to get_type returns the instance" do
      item_type = described_class.get_type(::String)

      expect(described_class.get_type(item_type)).to be(item_type)
    end

    context "instances" do
      subject { described_class.get_type(::String) }

      specify "return their type_name as a Saxon::QName" do
        expect(subject.type_name).to be_a(Saxon::QName)
      end

      specify "return their underlying Java object on request" do
        expect(subject.to_java).to be(S9API::ItemType::STRING)
      end

      context "instances referring to the same underlying type" do
        let(:other_instance) { described_class.new(S9API::ItemType::STRING) }

        specify "compare equal" do
          expect(subject).to eq(other_instance)
        end

        specify "generate the same code for #hash" do
          expect(subject.hash).to eq(other_instance.hash)
        end
      end

      context "returning value lexical strings from a Ruby object" do
        [
          ['xs:date', Time.utc(2001, 4, 1), '2001-04-01'],
          ['xs:date', Date.new(2001, 4, 1), '2001-04-01'],
          ['xs:date', DateTime.new(2001, 4, 1), '2001-04-01'],
          ['xs:date', '2001-04-01', '2001-04-01'],
          ['xs:dateTime', Time.utc(2001, 4, 1), '2001-04-01T00:00:00+00:00'],
          ['xs:dateTime', DateTime.new(2001, 4, 1, 0, 0, 0, '+02:00'), '2001-04-01T00:00:00+02:00'],
          ['xs:dateTime', '2001-04-01T00:00:00+00:00', '2001-04-01T00:00:00+00:00'],
          ['xs:dateTime', '2001-04-01T00:00:00Z', '2001-04-01T00:00:00Z'],
          ['xs:dateTimeStamp', Time.utc(2001, 4, 1), '2001-04-01T00:00:00+00:00'],
          ['xs:dateTimeStamp', DateTime.new(2001, 4, 1, 0, 0, 0, '+02:00'), '2001-04-01T00:00:00+02:00'],
          ['xs:time', '00:00:00', '00:00:00'],
          ['xs:time', '00:00:00Z', '00:00:00Z'],
          ['xs:time', '00:00:00+02:00', '00:00:00+02:00'],
          ['xs:integer', 1, '1'],
          ['xs:integer', -1, '-1'],
          ['xs:integer', 1.0, '1'],
          ['xs:short', 32767, '32767'],
          ['xs:short', -32768, '-32768'],
          ['xs:int', 2147483647, '2147483647'],
          ['xs:int', -2147483648, '-2147483648'],
          ['xs:long', 9223372036854775807, '9223372036854775807'],
          ['xs:long', -9223372036854775808, '-9223372036854775808'],
          ['xs:unsignedShort', 65535, '65535'],
          ['xs:unsignedInt', 4294967295, '4294967295'],
          ['xs:unsignedLong', 18446744073709551615, '18446744073709551615'],
          ['xs:positiveInteger', 1, '1'],
          ['xs:nonPositiveInteger', 0, '0'],
          ['xs:negativeInteger', -1, '-1'],
          ['xs:nonNegativeInteger', 0, '0'],
          ['xs:decimal', '1.0', '1.0'],
          ['xs:decimal', 1.0, '1.0'],
          ['xs:decimal', BigDecimal('1.0'), '1.0'],
          ['xs:float', 1.0, '1.0'],
          ['xs:float', 0, '0'],
          ['xs:float', 1, '1'],
          ['xs:float', '1', '1'],
          ['xs:float', BigDecimal('1'), /^0.1E1$/i], # JRuby 9.1 generates 0.1E1, 9.2 0.1e1
          ['xs:float', '1.0E15', '1.0E15'],
          ['xs:float', 'NaN', 'NaN'],
          ['xs:float', ::Float::NAN, 'NaN'],
          ['xs:float', 'INF', 'INF'],
          ['xs:float', ::Float::INFINITY, 'INF'],
          ['xs:float', '-INF', '-INF'],
          ['xs:float', ::Float::INFINITY * -1, '-INF'],
          ['xs:double', 1.0, '1.0'],
          ['xs:double', 0, '0.0'],
          ['xs:double', 1, '1.0'],
          ['xs:double', BigDecimal('1'), '1.0'],
          ['xs:double', '1.0E15', '1.0E15'],
          ['xs:double', 'NaN', 'NaN'],
          ['xs:double', ::Float::NAN, 'NaN'],
          ['xs:double', 'INF', 'INF'],
          ['xs:double', ::Float::INFINITY, 'INF'],
          ['xs:double', '-INF', '-INF'],
          ['xs:double', ::Float::INFINITY * -1, '-INF'],
          ['xs:duration', 'P1Y1M1DT1H1M1S', 'P1Y1M1DT1H1M1S'],
          ['xs:duration', 'P1Y', 'P1Y'],
          ['xs:duration', 1, 'PT1S'],
          ['xs:duration', -1, '-PT1S'],
          ['xs:duration', 1.0, 'PT1.000000000S'],
          ['xs:dayTimeDuration', 'P1DT1S', 'P1DT1S'],
          ['xs:dayTimeDuration', 1, 'PT1S'],
          ['xs:dayTimeDuration', -1, '-PT1S'],
          ['xs:dayTimeDuration', 1.0, 'PT1.000000000S'],
          ['xs:yearMonthDuration', 'P1Y', 'P1Y'],
          ['xs:yearMonthDuration', 'P1Y1M', 'P1Y1M'],
          ['xs:gDay', 1, '---01'],
          ['xs:gDay', 31, '---31'],
          ['xs:gDay', '---01', '---01'],
          ['xs:gDay', '---01Z', '---01Z'],
          ['xs:gDay', '---01+02:00', '---01+02:00'],
          ['xs:gMonth', 1, '--01'],
          ['xs:gMonth', 12, '--12'],
          ['xs:gMonth', '--01', '--01'],
          ['xs:gMonth', '--01Z', '--01Z'],
          ['xs:gMonth', '--01+02:00', '--01+02:00'],
          ['xs:gYear', 1, '0001'],
          ['xs:gYear', -1, '-0001'],
          ['xs:gYear', '2019', '2019'],
          ['xs:gYear', '2019Z', '2019Z'],
          ['xs:gYear', '2019+02:00', '2019+02:00'],
          ['xs:gYearMonth', '2019-01', '2019-01'],
          ['xs:gYearMonth', '2019-01Z', '2019-01Z'],
          ['xs:gYearMonth', '2019-01+02:00', '2019-01+02:00'],
          ['xs:gMonthDay', '--01-01', '--01-01'],
          ['xs:gMonthDay', '--01-01Z', '--01-01Z'],
          ['xs:gMonthDay', '--01-01+02:00', '--01-01+02:00'],
          ['xs:boolean', true, 'true'],
          ['xs:boolean', '', 'true'],
          ['xs:boolean', '1', 'true'],
          ['xs:boolean', '0', 'true'],
          ['xs:boolean', 'false', 'true'],
          ['xs:boolean', false, 'false'],
          ['xs:boolean', nil, 'false'],
          ['xs:NCName', 'a-name', 'a-name'],
          ['xs:NCName', 'a-name', 'a-name'],
          ['xs:Name', 'a-name', 'a-name'],
          ['xs:Name', 'a:name', 'a:name'],
          ['xs:anyURI', '/uri', '/uri'],
          ['xs:anyURI', URI('http://example.org/'), 'http://example.org/'],
          ['xs:ID', 'an-id', 'an-id'],
          ['xs:IDREF', 'an-id', 'an-id'],
          ['xs:token', 'token token', 'token token'],
          ['xs:NMTOKEN', 'an:nmtoken', 'an:nmtoken'],
          ['xs:normalizedString', 'normalized string', 'normalized string'],
          ['xs:ENTITY', 'entity-name', 'entity-name'],
          ['xs:language', 'de', 'de'],
          ['xs:language', 'zh-cmn-Hans-CN', 'zh-cmn-Hans-CN'],
          ['xs:base64Binary', 'encoded bytes', 'ZW5jb2RlZCBieXRlcw=='],
          ['xs:hexBinary', 'encoded bytes', '656e636f646564206279746573'],
          ['xs:byte', 'e', '101'],
          ['xs:byte', "\x92", '-110'],
          ['xs:unsignedByte', 'e', '101'],
          ['xs:unsignedByte', "\xb4", '180'],
        ].each do |type_name, ruby_value, expected_string|
          specify "generate an appropriate string for #{type_name} from <#{ruby_value.inspect}> (#{ruby_value.class.name})" do
            if expected_string.is_a?(Regexp)
              expect(described_class.get_type(type_name).lexical_string(ruby_value)).to match(expected_string)
            else
              expect(described_class.get_type(type_name).lexical_string(ruby_value)).to eq(expected_string)
            end
          end
        end

        context "raising errors when asked to generate a lexical string from bad data" do
          [
            ['xs:date', 'a', :BadRubyValue],
            ['xs:date', '2004/04/01', :BadRubyValue],
            ['xs:dateTime', 'a', :BadRubyValue],
            ['xs:dateTime', '2004-04-0100:00:00', :BadRubyValue],
            ['xs:dateTimeStamp', 'a', :BadRubyValue],
            ['xs:dateTimeStamp', '2004-04-01T00:00', :BadRubyValue],
            ['xs:time', 'a', :BadRubyValue],
            ['xs:time', '2004-04-01T00:00:00', :BadRubyValue],
            ['xs:integer', 'a', :BadRubyValue],
            ['xs:decimal', 'a', :BadRubyValue],
            ['xs:decimal', '1.0e4', :BadRubyValue],
            ['xs:float', 'a', :BadRubyValue],
            ['xs:float', '0.1E1.0', :BadRubyValue],
            ['xs:float', 'inf', :BadRubyValue],
            ['xs:float', 'Infinity', :BadRubyValue],
            ['xs:double', 'a', :BadRubyValue],
            ['xs:double', '0.1E1.0', :BadRubyValue],
            ['xs:double', 'inf', :BadRubyValue],
            ['xs:double', 'Infinity', :BadRubyValue],
            ['xs:short', 32768, :RubyValueOutOfBounds],
            ['xs:short', -32769, :RubyValueOutOfBounds],
            ['xs:int', 2147483648, :RubyValueOutOfBounds],
            ['xs:int', -2147483649, :RubyValueOutOfBounds],
            ['xs:long', 9223372036854775808, :RubyValueOutOfBounds],
            ['xs:long', -9223372036854775809, :RubyValueOutOfBounds],
            ['xs:unsignedShort', 65536, :RubyValueOutOfBounds],
            ['xs:unsignedShort', -1, :RubyValueOutOfBounds],
            ['xs:unsignedInt', 4294967296, :RubyValueOutOfBounds],
            ['xs:unsignedInt', -1, :RubyValueOutOfBounds],
            ['xs:unsignedLong', 18446744073709551616, :RubyValueOutOfBounds],
            ['xs:unsignedLong', -1, :RubyValueOutOfBounds],
            ['xs:positiveInteger', 0, :RubyValueOutOfBounds],
            ['xs:nonPositiveInteger', 1, :RubyValueOutOfBounds],
            ['xs:negativeInteger', 0, :RubyValueOutOfBounds],
            ['xs:nonNegativeInteger', -1, :RubyValueOutOfBounds],
            ['xs:duration', 'P', :BadRubyValue],
            ['xs:duration', '1', :BadRubyValue],
            ['xs:dayTimeDuration', 'P1M', :BadRubyValue],
            ['xs:yearMonthDuration', 1, :BadRubyValue],
            ['xs:yearMonthDuration', 'P1Y1M1D', :BadRubyValue],
            ['xs:yearMonthDuration', 'PT1H', :BadRubyValue],
            ['xs:gDay', 0, :RubyValueOutOfBounds],
            ['xs:gDay', 32, :RubyValueOutOfBounds],
            ['xs:gDay', '---32', :RubyValueOutOfBounds],
            ['xs:gDay', '---1', :BadRubyValue],
            ['xs:gDay', '01', :BadRubyValue],
            ['xs:gDay', '---01+0200', :BadRubyValue],
            ['xs:gMonth', 0, :RubyValueOutOfBounds],
            ['xs:gMonth', 13, :RubyValueOutOfBounds],
            ['xs:gMonth', '--13', :RubyValueOutOfBounds],
            ['xs:gMonth', '--1', :BadRubyValue],
            ['xs:gMonth', '01', :BadRubyValue],
            ['xs:gMonth', '--01+0200', :BadRubyValue],
            ['xs:gYear', 0, :RubyValueOutOfBounds],
            ['xs:gYear', '0000', :RubyValueOutOfBounds],
            ['xs:gYear', '--1', :BadRubyValue],
            ['xs:gYear', '01', :BadRubyValue],
            ['xs:gYear', '--01+0200', :BadRubyValue],
            ['xs:gYearMonth', '0000-01', :RubyValueOutOfBounds],
            ['xs:gYearMonth', '2019-13', :RubyValueOutOfBounds],
            ['xs:gYearMonth', '0001', :BadRubyValue],
            ['xs:gYearMonth', '19-01', :BadRubyValue],
            ['xs:gYearMonth', '2019-01+0200', :BadRubyValue],
            ['xs:gMonthDay', '--01-32', :RubyValueOutOfBounds],
            ['xs:gMonthDay', '--02-30', :RubyValueOutOfBounds],
            ['xs:gMonthDay', '11-11+0200', :BadRubyValue],
            ['xs:NCName', 'a:name', :BadRubyValue],
            ['xs:NCName', '1name', :BadRubyValue],
            ['xs:Name', '1name', :BadRubyValue],
            ['xs:anyURI', '<%>', :BadRubyValue],
            ['xs:ID', 'an:id', :BadRubyValue],
            ['xs:IDREF', 'an:id', :BadRubyValue],
            ['xs:token', "token  token", :BadRubyValue],
            ['xs:token', "token\ttoken", :BadRubyValue],
            ['xs:token', " token ", :BadRubyValue],
            ['xs:token', "token\ntoken", :BadRubyValue],
            ['xs:NMTOKEN', "nmtoken nmtoken", :BadRubyValue],
            ['xs:normalizedString', "not\nnormalized", :BadRubyValue],
            ['xs:ENTITY', "entity:name", :BadRubyValue],
            ['xs:language', "morethaneightletters", :BadRubyValue],
            ['xs:QName', "a:thingy", :UnconvertableNamespaceSensitveItemType],
            ['xs:NOTATION', "thingy", :UnconvertableNamespaceSensitveItemType],
            ['xs:byte', "AA", :RubyValueOutOfBounds],
            ['xs:unsignedByte', "AA", :RubyValueOutOfBounds],
          ].each do |type_name, ruby_value, error_const|
            specify "raises an #{error_const} error when asked to convert #{ruby_value.inspect} (#{ruby_value.class.name}) to #{type_name}" do
              expect {
                described_class.get_type(type_name).lexical_string(ruby_value)
              }.to raise_error(ItemType::LexicalStringConversion::Errors.const_get(error_const))
            end
          end
        end
      end

      context "generating Ruby values from a typed XDM value" do
        [
          ['xs:integer', '1', 1],
          ['xs:decimal', '1', BigDecimal('1')],
          ['xs:float', '1', 1.0],
          ['xs:double', '1', 1.0],
          ['xs:int', '1', 1],
          ['xs:short', '-1', -1],
          ['xs:long', '1', 1],
          ['xs:unsignedInt', '1', 1],
          ['xs:unsignedShort', '1', 1],
          ['xs:unsignedLong', '1', 1],
          ['xs:positiveInteger', '1', 1],
          ['xs:nonPositiveInteger', '-1', -1],
          ['xs:negativeInteger', '-1', -1],
          ['xs:nonNegativeInteger', '1', 1],
          ['xs:dateTime', '2019-09-27T14:42:00', Time.local(2019, 9, 27, 14, 42, 0)],
          ['xs:dateTime', '2019-09-27T14:42:00Z', Time.new(2019, 9, 27, 14, 42, 0, '+00:00')],
          ['xs:dateTimeStamp', '2019-09-27T14:42:00Z', Time.new(2019, 9, 27, 14, 42, 0, '+00:00')],
          ['xs:boolean', 'true', true],
          ['xs:boolean', '1', true],
          ['xs:boolean', 'false', false],
          ['xs:boolean', '0', false],
        ].each do |type_name, lexical_string, expected|
          specify "generate an appropriate Ruby value of class #{expected.class.name} from the XDM type #{type_name}" do
            item_type = described_class.get_type(type_name)
            value = Saxon::XDM::AtomicValue.from_lexical_string(lexical_string, item_type)
            ruby_value = item_type.ruby_value(value)

            expect(ruby_value).to match_ruby_value_and_class(expected)
          end
        end

        specify "return a Saxon::QName for an XDM Atomic Value containing a QName" do
          item_type = described_class.get_type('xs:QName')
          qname = Saxon::QName.clark('{http://example.org/#ns}el')
          value = Saxon::XDM::AtomicValue.create(qname)

          expect(item_type.ruby_value(value)).to eq(qname)
        end

        context "encoded binary datatypes return an ASCII-8bit encoded string" do
          specify "from an xs:base64Binary" do
            item_type = described_class.get_type('xs:base64Binary')
            value = Saxon::XDM::AtomicValue.from_lexical_string('ZGVjb2RlZCBieXRlcw==', item_type)
            ruby_value = item_type.ruby_value(value)

            expect(ruby_value).to eq('decoded bytes')
            expect(ruby_value.encoding).to be(Encoding::ASCII_8BIT)
          end

          specify "from an xs:hexBinary" do
            item_type = described_class.get_type('xs:hexBinary')
            value = Saxon::XDM::AtomicValue.from_lexical_string('6465636f646564206279746573', item_type)
            ruby_value = item_type.ruby_value(value)

            expect(ruby_value).to eq('decoded bytes')
            expect(ruby_value.encoding).to be(Encoding::ASCII_8BIT)
          end

          specify "from an xs:byte" do
            item_type = described_class.get_type('xs:byte')
            value = Saxon::XDM::AtomicValue.from_lexical_string('-110', item_type)
            ruby_value = item_type.ruby_value(value)

            expect(ruby_value).to eq("\x92".force_encoding(Encoding::ASCII_8BIT))
            expect(ruby_value.encoding).to be(Encoding::ASCII_8BIT)
          end

          specify "from an xs:unsignedByte" do
            item_type = described_class.get_type('xs:unsignedByte')
            value = Saxon::XDM::AtomicValue.from_lexical_string('180', item_type)
            ruby_value = item_type.ruby_value(value)

            expect(ruby_value).to eq("\xb4".force_encoding(Encoding::ASCII_8BIT))
            expect(ruby_value.encoding).to be(Encoding::ASCII_8BIT)
          end
        end
      end
    end
  end

  RSpec.describe ItemType::Factory do
    let(:processor) { Saxon::Processor.create }

    describe "instantiating" do
      it "requires a Processor" do
        decl = described_class.new(processor)
        expect(decl).to be_a(Saxon::ItemType::Factory)
      end
    end
  end
end
