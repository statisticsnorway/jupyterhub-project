
# shutdown the server after no activity for an hour
c.NotebookApp.shutdown_no_activity_timeout = 60 * 60
# shutdown kernels after no activity for 30 minutes
c.MappingKernelManager.cull_idle_timeout = 30 * 60
# check for idle kernels every two minutes
c.MappingKernelManager.cull_interval = 2 * 60

c.Application.log_level = 'WARN'
