# frozen_string_literal: true

require "rails_helper"

RSpec.describe Integrations::Xero::UpdateService, type: :service do
  let(:integration) { create(:xero_integration, organization:) }
  let(:organization) { membership.organization }
  let(:membership) { create(:membership) }

  describe "#call" do
    subject(:service_call) { described_class.call(integration:, params: update_args) }

    before { integration }

    let(:name) { "Xero 1" }

    let(:update_args) do
      {
        name:,
        code: "xero1"
      }
    end

    context "without premium license" do
      it "returns an error" do
        result = service_call

        aggregate_failures do
          expect(result).not_to be_success
          expect(result.error).to be_a(BaseService::MethodNotAllowedFailure)
        end
      end
    end

    context "with premium license" do
      around { |test| lago_premium!(&test) }

      context "when xero premium integration is not present" do
        it "returns an error" do
          result = service_call

          aggregate_failures do
            expect(result).not_to be_success
            expect(result.error).to be_a(BaseService::MethodNotAllowedFailure)
          end
        end
      end

      context "when xero premium integration is present" do
        before do
          organization.update!(premium_integrations: ["xero"])
        end

        context "without validation errors" do
          it "updates an integration" do
            service_call

            integration = Integrations::XeroIntegration.order(updated_at: :desc).first
            expect(integration.name).to eq(name)
          end

          it "returns an integration in result object" do
            result = service_call

            expect(result.integration).to be_a(Integrations::XeroIntegration)
          end
        end

        context "with validation error" do
          let(:name) { nil }

          it "returns an error" do
            result = service_call

            aggregate_failures do
              expect(result).not_to be_success
              expect(result.error).to be_a(BaseService::ValidationFailure)
              expect(result.error.messages[:name]).to eq(["value_is_mandatory"])
            end
          end
        end
      end
    end
  end
end
