Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.max_attempts = 1
Delayed::Worker.max_run_time = 24.hours
Delayed::Worker.delay_jobs = !Rails.env.test?