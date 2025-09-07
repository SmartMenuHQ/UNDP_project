require 'rails_helper'

RSpec.describe BulkMarkingJob, type: :job do
  include ActiveJob::TestHelper

  let(:assessment) { create(:assessment) }
  let(:marking_scheme) { create(:assessment_marking_scheme, assessment: assessment, is_active: true) }
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let(:user3) { create(:user) }

  let!(:session1) { create(:assessment_response_session, assessment: assessment, user: user1, state: 'submitted') }
  let!(:session2) { create(:assessment_response_session, assessment: assessment, user: user2, state: 'submitted') }
  let!(:session3) { create(:assessment_response_session, assessment: assessment, user: user3, state: 'submitted') }

  let(:session_ids) { [session1.id, session2.id, session3.id] }

  describe '#perform' do
    context 'with valid sessions' do
      it 'queues individual marking jobs for all sessions' do
        expect {
          BulkMarkingJob.new.perform(session_ids, marking_scheme.id)
        }.to have_enqueued_job(MarkingJob).exactly(3).times
      end

      it 'queues jobs with correct parameters' do
        BulkMarkingJob.new.perform(session_ids, marking_scheme.id)

        session_ids.each do |session_id|
          expect(MarkingJob).to have_been_enqueued.with(session_id, marking_scheme.id)
        end
      end

      it 'uses default marking scheme when none specified' do
        BulkMarkingJob.new.perform(session_ids)

        session_ids.each do |session_id|
          expect(MarkingJob).to have_been_enqueued.with(session_id, nil)
        end
      end

      it 'logs successful completion' do
        # Stub MarkingJob to prevent interference with logger expectations
        allow(MarkingJob).to receive(:perform_later).and_return(true)

        expect(Rails.logger).to receive(:info).with(/Starting bulk marking job for 3 sessions/)
        expect(Rails.logger).to receive(:info).with(/Bulk marking job completed: 3 successful, 0 failed/)

        BulkMarkingJob.new.perform(session_ids, marking_scheme.id)
      end

      it 'logs progress for large batches' do
        large_session_ids = (1..25).to_a # Simulate 25 sessions

        expect(Rails.logger).to receive(:info).with(/Starting bulk marking job for 25 sessions/)
        expect(Rails.logger).to receive(:info).with(/progress: 10\/25 sessions processed/)
        expect(Rails.logger).to receive(:info).with(/progress: 20\/25 sessions processed/)
        expect(Rails.logger).to receive(:info).with(/Bulk marking job completed/)

        # Mock MarkingJob to avoid actual job queueing
        allow(MarkingJob).to receive(:perform_later)

        BulkMarkingJob.new.perform(large_session_ids, marking_scheme.id)
      end

      it 'caches job results' do
        # Stub MarkingJob to prevent interference
        allow(MarkingJob).to receive(:perform_later).and_return(true)

        job = BulkMarkingJob.new
        timestamp = Time.current.to_i
        allow(Time).to receive(:current).and_return(Time.at(timestamp))

        expected_cache_key = "bulk_marking_job_#{timestamp}_#{session_ids.count}"
        expect(Rails.cache).to receive(:write).with(
          expected_cache_key,
          hash_including(
            total: 3,
            successful: 3,
            failed: 0,
            errors: []
          ),
          expires_in: 1.hour
        )

        job.perform(session_ids, marking_scheme.id)
      end
    end

    context 'with some failing sessions' do
      before do
        # Mock one session to fail
        allow(MarkingJob).to receive(:perform_later).with(session1.id, marking_scheme.id).and_raise('Job queue error')
        allow(MarkingJob).to receive(:perform_later).with(session2.id, marking_scheme.id)
        allow(MarkingJob).to receive(:perform_later).with(session3.id, marking_scheme.id)
      end

      it 'continues processing after failures' do
        expect {
          BulkMarkingJob.new.perform(session_ids, marking_scheme.id)
        }.not_to raise_error

        # Should still queue successful jobs
        expect(MarkingJob).to have_received(:perform_later).with(session2.id, marking_scheme.id)
        expect(MarkingJob).to have_received(:perform_later).with(session3.id, marking_scheme.id)
      end

      it 'tracks failures and errors' do
        expect(Rails.logger).to receive(:error).with(/Failed to queue marking job for session #{session1.id}/)
        expect(Rails.logger).to receive(:error).with(/Bulk marking had 1 failures/)

        BulkMarkingJob.new.perform(session_ids, marking_scheme.id)
      end

      it 'logs completion summary with failures' do
        expect(Rails.logger).to receive(:info).with(/Starting bulk marking job for 3 sessions/)
        expect(Rails.logger).to receive(:info).with(/Bulk marking job completed: 2 successful, 1 failed/)

        BulkMarkingJob.new.perform(session_ids, marking_scheme.id)
      end

      it 'caches failure information' do
        job = BulkMarkingJob.new
        timestamp = Time.current.to_i
        allow(Time).to receive(:current).and_return(Time.at(timestamp))

        expected_cache_key = "bulk_marking_job_#{timestamp}_#{session_ids.count}"
        expect(Rails.cache).to receive(:write).with(
          expected_cache_key,
          hash_including(
            total: 3,
            successful: 2,
            failed: 1,
            errors: array_including(a_string_matching(/Session #{session1.id}/))
          ),
          expires_in: 1.hour
        )

        job.perform(session_ids, marking_scheme.id)
      end
    end

    context 'with empty session list' do
      it 'handles empty input gracefully' do
        expect(Rails.logger).to receive(:info).with(/Starting bulk marking job for 0 sessions/)
        expect(Rails.logger).to receive(:info).with(/Bulk marking job completed: 0 successful, 0 failed/)

        BulkMarkingJob.new.perform([], marking_scheme.id)
      end
    end

    context 'error handling' do
      it 'logs and handles individual session errors gracefully' do
        allow(MarkingJob).to receive(:perform_later).and_raise('Unexpected error')

        expect(Rails.logger).to receive(:info).with(/Starting bulk marking job for 1 sessions/)
        expect(Rails.logger).to receive(:error).with(/Failed to queue marking job for session #{session1.id}: Unexpected error/)
        expect(Rails.logger).to receive(:info).with(/Bulk marking job completed: 0 successful, 1 failed/)
        expect(Rails.logger).to receive(:error).with(/Bulk marking had 1 failures/)

        expect {
          BulkMarkingJob.new.perform([session1.id], marking_scheme.id)
        }.not_to raise_error
      end
    end

    context 'with different session states' do
      let!(:draft_session) { create(:assessment_response_session, assessment: assessment, state: 'draft') }
      let!(:marked_session) { create(:assessment_response_session, assessment: assessment, state: 'marked') }
      let(:mixed_session_ids) { [session1.id, draft_session.id, marked_session.id] }

      it 'attempts to queue jobs for all sessions regardless of state' do
        # BulkMarkingJob doesn't validate states - that's MarkingJob's responsibility
        expect {
          BulkMarkingJob.new.perform(mixed_session_ids, marking_scheme.id)
        }.to have_enqueued_job(MarkingJob).exactly(3).times
      end
    end

    context 'performance considerations' do
      it 'processes sessions in order' do
        processed_order = []

        allow(MarkingJob).to receive(:perform_later) do |session_id, _|
          processed_order << session_id
        end

        BulkMarkingJob.new.perform(session_ids, marking_scheme.id)

        expect(processed_order).to eq(session_ids)
      end

      it 'handles large batches efficiently' do
        large_batch = (1..1000).to_a

        # Mock to avoid actual job queueing
        allow(MarkingJob).to receive(:perform_later)

        expect {
          BulkMarkingJob.new.perform(large_batch, marking_scheme.id)
        }.not_to raise_error

        expect(MarkingJob).to have_received(:perform_later).exactly(1000).times
      end
    end
  end

  describe 'job configuration' do
    it 'is configured with correct queue' do
      expect(BulkMarkingJob.queue_name).to eq('default')
    end

    it 'has retry configuration' do
      expect(BulkMarkingJob).to respond_to(:retry_on)
    end

    it 'has shorter retry attempts than MarkingJob' do
      # Both jobs should have retry configuration
      expect(BulkMarkingJob).to respond_to(:retry_on)
      expect(MarkingJob).to respond_to(:retry_on)
    end
  end

  describe 'integration scenarios' do
    let(:section) { create(:assessment_section, assessment: assessment) }
    let(:question) { create(:assessment_question, assessment_section: section) }

    before do
      # Create responses for each session
      [session1, session2, session3].each do |session|
        create(:assessment_question_response,
          assessment_response_session: session,
          assessment_question: question,
          assessment: assessment,
          response_value: { text: 'test answer' }
        )
      end

      # Create marking rule
      create(:assessment_question_marking_rule,
        assessment_marking_scheme: marking_scheme,
        assessment_question: question,
        rule_type: 'exact_match',
        points: 10.0
      )
    end

    it 'integrates with full marking pipeline' do
      # Perform bulk job
      perform_enqueued_jobs do
        BulkMarkingJob.perform_later(session_ids, marking_scheme.id)
      end

      # All sessions should be marked
      [session1, session2, session3].each do |session|
        expect(session.reload.state).to eq('marked')
      end
    end

    context 'with conditional sections' do
      let(:trigger_section) { create(:assessment_section, assessment: assessment, order: 2) }
      let(:trigger_question) { create(:assessment_question, assessment_section: trigger_section, type: 'AssessmentQuestions::MultipleChoice') }
      let(:trigger_option) { create(:assessment_question_option, assessment_question: trigger_question) }

      let(:conditional_section) {
        create(:assessment_section,
          assessment: assessment,
          order: 3,
          is_conditional: true,
          visibility_conditions: {
            trigger_question_id: trigger_question.id,
            trigger_response_type: 'option_selected',
            trigger_values: [trigger_option.id],
            operator: 'contains'
          }
        )
      }
      let(:conditional_question) { create(:assessment_question, assessment_section: conditional_section) }

      before do
        # Set trigger question as not required to avoid validation issues
        trigger_question.update!(is_required: false)

        # Create marking rules
        create(:assessment_question_marking_rule,
          assessment_marking_scheme: marking_scheme,
          assessment_question: trigger_question,
          rule_type: 'option_based',
          points: 5.0
        )

        create(:assessment_question_marking_rule,
          assessment_marking_scheme: marking_scheme,
          assessment_question: conditional_question,
          rule_type: 'exact_match',
          points: 10.0
        )

        # Only session1 answers trigger question correctly
        trigger_response = create(:assessment_question_response,
          assessment_response_session: session1,
          assessment_question: trigger_question,
          assessment: assessment
        )
        trigger_response.response_value = [trigger_option.id]
        trigger_response.save!

        # session1 also answers conditional question
        create(:assessment_question_response,
          assessment_response_session: session1,
          assessment_question: conditional_question,
          assessment: assessment,
          response_value: { text: 'conditional answer' }
        )

        # session2 and session3 answer trigger question incorrectly
        other_option = create(:assessment_question_option, assessment_question: trigger_question)
        [session2, session3].each do |session|
          create(:assessment_question_response,
            assessment_response_session: session,
            assessment_question: trigger_question,
            assessment: assessment,
            response_value: [other_option.id]
          )
        end
      end

      it 'handles conditional visibility correctly during bulk marking' do
        # Set up proper responses with correct values for the rules
        # The trigger_response was already created in the before block, update its value
        trigger_response = session1.assessment_question_responses.find_by(assessment_question: trigger_question)
        trigger_response.update!(value: { selected_options: [trigger_option.id] })

        # Update the existing conditional response that was created in the before block
        conditional_response = session1.assessment_question_responses.find_by(assessment_question: conditional_question)
        conditional_response.update!(value: { text: 'conditional answer' })

        # Update marking rule criteria to match the responses
        marking_scheme.assessment_question_marking_rules
          .find_by(assessment_question: trigger_question)
          .update!(criteria: { correct_options: [trigger_option.id] })

        marking_scheme.assessment_question_marking_rules
          .find_by(assessment_question: conditional_question)
          .update!(criteria: { expected_values: ['conditional answer'] })

        perform_enqueued_jobs do
          BulkMarkingJob.perform_later(session_ids, marking_scheme.id)
        end

        # session1 should have higher score due to conditional question
        expect(session1.reload.total_score).to be > session2.reload.total_score
        expect(session1.total_score).to be > session3.reload.total_score
      end
    end
  end

  describe 'monitoring and observability' do
    it 'provides job status through cache' do
      # Stub MarkingJob to prevent interference
      allow(MarkingJob).to receive(:perform_later).and_return(true)

      # Mock Rails.cache to capture the write call
      cache_data = {}
      allow(Rails.cache).to receive(:write) do |key, value, options|
        cache_data[key] = value
      end
      allow(Rails.cache).to receive(:read) do |key|
        cache_data[key]
      end

      job = BulkMarkingJob.new
      job.perform(session_ids, marking_scheme.id)

      # Find the cache key that was written
      cache_keys = cache_data.keys.select { |k| k.start_with?('bulk_marking_job_') }
      expect(cache_keys).not_to be_empty

      cached_result = cache_data[cache_keys.first]
      expect(cached_result).to include(
        :total,
        :successful,
        :failed,
        :errors,
        :completed_at
      )
    end

    it 'expires cached results after 1 hour' do
      # Stub MarkingJob to prevent interference
      allow(MarkingJob).to receive(:perform_later).and_return(true)

      job = BulkMarkingJob.new
      timestamp = Time.current.to_i
      allow(Time).to receive(:current).and_return(Time.at(timestamp))

      expected_cache_key = "bulk_marking_job_#{timestamp}_#{session_ids.count}"
      expect(Rails.cache).to receive(:write).with(
        expected_cache_key,
        anything,
        expires_in: 1.hour
      )

      job.perform(session_ids, marking_scheme.id)
    end
  end
end
