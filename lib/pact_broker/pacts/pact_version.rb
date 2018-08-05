require 'sequel'

module PactBroker
  module Pacts
    class PactVersion < Sequel::Model(:pact_versions)
      one_to_many :pact_publications, reciprocal: :pact_version
      one_to_many :verifications, reciprocal: :verification, order: :id, :class => "PactBroker::Domain::Verification"

      def name
        "Pact between #{consumer_name} and #{provider_name}"
      end

      def provider_name
        pact_publications.last.provider.name
      end

      def consumer_name
        pact_publications.last.consumer.name
      end

      def latest_consumer_version
        consumer_versions.last
      end

      def latest_pact_publication
        PactBroker::Pacts::LatestPactPublicationsByConsumerVersion
          .where(pact_version_id: id)
          .order(:consumer_version_order)
          .last || PactBroker::Pacts::AllPactPublications
          .where(pact_version_id: id)
          .order(:consumer_version_order)
          .last
      end

      def latest_verification
        verifications.last
      end

      def consumer_versions
        PactBroker::Domain::Version.where(id: PactBroker::Pacts::PactPublication.select(:consumer_version_id).where(pact_version_id: id)).order(:order)
      end

      def latest_consumer_version_number
        latest_consumer_version.number
      end
    end

    PactVersion.plugin :timestamps
  end
end

# Table: pact_versions
# Columns:
#  id          | integer                     | PRIMARY KEY DEFAULT nextval('pact_versions_id_seq'::regclass)
#  consumer_id | integer                     | NOT NULL
#  provider_id | integer                     | NOT NULL
#  sha         | text                        | NOT NULL
#  content     | text                        |
#  created_at  | timestamp without time zone | NOT NULL
# Indexes:
#  pact_versions_pkey   | PRIMARY KEY btree (id)
#  unq_pvc_con_prov_sha | UNIQUE btree (consumer_id, provider_id, sha)
# Foreign key constraints:
#  pact_versions_consumer_id_fkey | (consumer_id) REFERENCES pacticipants(id)
#  pact_versions_provider_id_fkey | (provider_id) REFERENCES pacticipants(id)
# Referenced By:
#  pact_publications                                            | pact_publications_pact_version_id_fkey                          | (pact_version_id) REFERENCES pact_versions(id)
#  verifications                                                | verifications_pact_version_id_fkey                              | (pact_version_id) REFERENCES pact_versions(id)
#  latest_pact_publication_ids_by_consumer_versions             | latest_pact_publication_ids_by_consumer_ve_pact_version_id_fkey | (pact_version_id) REFERENCES pact_versions(id) ON DELETE CASCADE
#  latest_verification_id_for_pact_version_and_provider_version | latest_v_id_for_pv_and_pv_pact_version_id_fk                    | (pact_version_id) REFERENCES pact_versions(id) ON DELETE CASCADE
