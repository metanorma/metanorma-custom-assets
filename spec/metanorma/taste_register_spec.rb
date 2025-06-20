require_relative "../spec_helper"

RSpec.describe Metanorma::TasteRegister do
  let(:register) { described_class.instance }

  describe "#available_tastes" do
    it "returns available tastes" do
      expect(register.available_tastes).to include(:icc)
    end
  end

  describe "#taste_info" do
    it "returns taste information" do
      info = register.taste_info(:icc)
      expect(info[:flavor]).to eq(:icc)
      expect(info[:owner]).to eq("International Color Consortium")
      expect(info[:base_flavor]).to eq(:iso)
      expect(info[:base_override]).to include("publisher" => "International Color Consortium")
      expect(info[:doctypes]).to include(
      {"taste" => "specification", "base"=> "international-standard", "override-attributes" =>
  [{"presentation-metadata-color-secondary" => '#376795'}]}
      )

    end
  end

  describe "#get" do
    it "returns a taste instance" do
      taste = register.get(:icc)
      expect(taste).to be_a(Metanorma::Taste::Base)
      expect(taste.flavor).to eq(:icc)
    end

    it "returns a dynamically created class" do
      taste = register.get(:icc)
      expect(taste).to be_a(Metanorma::Taste::Icc)
      expect(taste.class.to_s).to eq("Metanorma::Taste::Icc")
    end

    it "caches taste instances" do
      taste1 = register.get(:icc)
      taste2 = register.get(:icc)
      expect(taste1).to be(taste2)
    end

    it "raises an error for unknown taste" do
      expect do
        register.get(:unknown)
      end.to raise_error(RuntimeError, "Unknown taste: unknown")
    end
  end

  describe "#process_input_adoc_overrides" do
    let(:attrs) { [":doctype: specification"] }
    let(:options) { {} }
    let(:taste) { described_class.get(:icc) }

    let(:expected_boilerplate_path) do
      # Get the actual path from the taste info
      info = described_class.instance.taste_info(:icc)
      File.join(info[:directory], info[:copyright_notice])
    end
    let(:expected_i18n_path) do
      # Get the actual path from the taste info
      info = described_class.instance.taste_info(:icc)
      File.join(info[:directory], info[:i18n_dictionary])
    end

    it "adds the correct attributes and updates options" do
      result = taste.process_input_adoc_overrides(attrs, options)

      # Check that the method returns the modified attrs array
      expect(result).to eq(attrs)

      # Check that the attrs array contains the expected values
      expect(attrs).to include(":boilerplate-authority: #{expected_boilerplate_path}")
      expect(attrs).to include(":i18nyaml: #{expected_i18n_path}")
      expect(attrs).to include(":publisher: International Color Consortium")
      expect(attrs).to include(":publisher_abbr: ICC")
      expect(attrs).to include(":presentation-metadata-color-secondary: #376795")
      expect(attrs).to include(":presentation-metadata-backcover-text: color.org")
      expect(attrs).to include(":doctype: international-standard")
      expect(attrs).to include(":presentation-metadata-doctype-alias: specification")

      # Check that the options hash is updated
      expect(options[":boilerplate-authority:"]).to eq(expected_boilerplate_path)
    end

    it "generates output with the correct boilerplate path" do
      taste.process_input_adoc_overrides(attrs, options)

      # Verify the boilerplate file exists
      expect(File.exist?(expected_boilerplate_path)).to be true

      # Verify the boilerplate file contains expected content
      boilerplate_content = File.read(expected_boilerplate_path)
      expect(boilerplate_content)
        .to include("Copyright (c) {{ docyear }} International Color Consortium")
      expect(boilerplate_content)
        .to include("International Color Consortium and the ICC logo are registered trademarks")
      expect(boilerplate_content)
        .to include("Visit the ICC Web site: http://www.color.org")
    end
  end
end
