module Postnhost
  module SchemaHelper
    ORGANIZATION_TYPES = {
      "Organization" => "A general organization that does not fit a specific media type.",
      "MediaOrganization" => "A company producing mixed media content.",
      "OnlineBusiness" => "A web-only publication with no print or broadcast edition.",
      "Periodical" => "A magazine, journal, or newsletter with recurring issues.",
      "Brand" => "A publication that is a product or imprint.",
      "NewsMediaOrganization" => "A news outlet producing journalism.",
      "Corporation" => "A formally registered media company.",
      "LocalBusiness" => "A local or regional publication with a physical office.",
      "NGO" => "A nonprofit or donor-funded media organization.",
      "GovernmentOrganization" => "A state-funded or public broadcaster.",
      "EducationalOrganization" => "A university press, student paper, or academic journal."
    }.freeze

    ARTICLE_TYPES = {
      "Article" => "A general-purpose article.",
      "BlogPosting" => "A blog post, often opinion-driven or informal.",
      "NewsArticle" => "A news story about a current event.",
      "Report" => "A structured report of findings or investigation.",
      "TechArticle" => "Technical guides, docs, or tutorials.",
      "OpinionNewsArticle" => "News-oriented editorial opinion.",
      "AnalysisNewsArticle" => "Analysis and interpretation of a news event.",
      "ReviewNewsArticle" => "A review of a product, event, policy, or person.",
      "BackgroundNewsArticle" => "Background context explaining a current story.",
      "ReportageNewsArticle" => "On-the-ground field reporting.",
      "SatiricalArticle" => "Satire using humor or irony.",
      "ScholarlyArticle" => "Academic or peer-reviewed content.",
      "MedicalWebPage" => "Health or medical content.",
      "APIReference" => "Technical reference docs for an API."
    }.freeze

    POLICY_FIELDS = {
      "publishing_principles" => "publishingPrinciples",
      "corrections_policy" => "correctionsPolicy",
      "ethics_policy" => "ethicsPolicy",
      "ownership_funding_info" => "ownershipFundingInfo",
      "actionable_feedback_policy" => "actionableFeedbackPolicy",
      "verification_fact_checking_policy" => "verificationFactCheckingPolicy",
      "masthead" => "masthead",
      "diversity_policy" => "diversityPolicy",
      "diversity_staffing_report" => "diversityStaffingReport",
      "unnamed_sources_policy" => "unnamedSourcesPolicy",
      "no_bylines_policy" => "noBylinesPolicy",
      "mission_coverage_priorities_policy" => "missionCoveragePrioritiesPolicy"
    }.freeze

    CONTACT_TYPES = [
      "editorial",
      "customer service",
      "press",
      "technical support"
    ].freeze

    AUTHOR_ALUMNI_TYPES = %w[
      EducationalOrganization
      CollegeOrUniversity
      School
      HighSchool
      MiddleSchool
      ElementarySchool
      Preschool
    ].freeze

    SETTINGS_TEXT_OVERRIDE_FIELDS = %w[
      website_name
      website_description
      organization_name
      organization_alternate_name
      organization_description
    ].freeze

    def schema_organization_type_options
      ORGANIZATION_TYPES.map { |name, description| ["#{name} - #{description}", name] }
    end

    def schema_article_type_options
      ARTICLE_TYPES.map { |name, description| ["#{name} - #{description}", name] }
    end

    def schema_policy_fields
      POLICY_FIELDS
    end

    def schema_contact_type_options
      CONTACT_TYPES
    end

    def schema_author_alumni_type_options
      AUTHOR_ALUMNI_TYPES
    end

    def schema_multiline_to_array(value)
      value.to_s.lines.map(&:strip).compact_blank.uniq
    end

    def schema_array_to_multiline(value)
      value.to_a.map(&:to_s).compact_blank.join("\n")
    end
  end
end
