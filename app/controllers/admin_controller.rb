class AdminController < ApplicationController
  # Simple admin endpoints for monitoring

  def job_status
    begin
      # Get job counts from Solid Queue
      stats = {
        queued: SolidQueue::Job.where(finished_at: nil).count,
        running: SolidQueue::Job.joins(:claimed_execution).count,
        failed: SolidQueue::Job.joins(:failed_execution).count,
        total: SolidQueue::Job.count,
      }

      render json: stats
    rescue => e
      Rails.logger.error "Error fetching job status: #{e.message}"
      render json: { error: "Unable to fetch job status" }, status: :internal_server_error
    end
  end

  def jobs
    @jobs = SolidQueue::Job.order(created_at: :desc).limit(50)
    @stats = {
      total: SolidQueue::Job.count,
      queued: SolidQueue::Job.where(finished_at: nil).count,
      running: SolidQueue::Job.joins(:claimed_execution).count,
      failed: SolidQueue::Job.joins(:failed_execution).count,
      succeeded: SolidQueue::Job.where.not(finished_at: nil).joins("LEFT JOIN solid_queue_failed_executions ON solid_queue_jobs.id = solid_queue_failed_executions.job_id").where(solid_queue_failed_executions: { job_id: nil }).count,
    }
  end
end
