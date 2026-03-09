Summary
=======
The Parameter ESTimation (PEST), PEST++, and PEST_HP software suites are
collections of tools for parameter estimation and uncertainty analysis in
modeling. They provide a framework for optimizing model parameters to find the
best match between simulation and observed data, assess model performance,
and quantify uncertainty in model predictions.

These software suites each come with their own way of handling parallelization,
which can significantly speed up the optimization process. The scripts provided
in this repository are designed to facilitate the connection between the PEST
parallelization capabilities and the Distributed Resource Managers SLURM and
PBS.

PEST/PEST++/PEST_HP Parallelization
===================================
Within PEST, PEST_HP, and PEST++ the parallelization of the optimization is
achieved through a manager-agent architecture, where a manager process
distributes parameter sets to multiple agent processes where each agent runs
models serially. The results from the agents are then collected by the manager
for analysis and further optimization.

First a manager process is started that waits for agents to connect. Then,
multiple agent processes are started, which connect to the manager and wait for
parameter sets to be distributed. The manager distributes parameter sets to the
agents, which run the model and return the results to the manager. This process
is repeated for multiple iterations until the optimization is complete. The
communication between the manager and agents can be visualized as follows.

::

                                | Iteration 1 | Iteration 2 | ... | Iteration M
    Manager |<--> Agent 1 |<++> | Model 1     | Model N+1   | ... | Model 2NM+1
            |<--> Agent 2 |<++> | Model 2     | Model N+2   | ... | Model 2NM+2
            |<--> Agent 3 |<++> | Model 3     | Model N+3   | ... | Model 2NM+3
             .
             .
             .
            |<--> Agent N |<++> | Model N     | Model 2N    | ... | Model 2NM+N

    |<--> is the communication between the manager and agents, where the
          manager distributes parameter sets to the agents and waits for the
          agents to complete their assigned model runs and return the results.
    |<++> is the agent creating model input files, running the model, and
          returning the results to the manager.
    N     is the number of agents running in parallel. The optimum number of
          agents is (2*(number of parameters being optimized)+1).  Allocating
          more agents than this will not speed up the optimization.
    M     is the number of iterations in the optimization process, which is
          determined by the optimization algorithm and the convergence
          criteria.

This parallelization approach does not monitor any resources, and the running
of the manager and agents is external to the parallelization framework. This
means that the user is responsible for starting the manager and agents, and
ensuring that they are running correctly. The scripts provided in this
repository are designed to facilitate this process, by providing a way to start
the manager and agents in a parallelized manner using SLURM or PBS.

Overview of the Scripts
=======================

+-------------------------+-------+---------+------------------------------------------+
| Script Name             | Link  | Suite   | Description                              |
|                         | to    |         |                                          |
|                         | qpest |         |                                          |
+=========================+=======+=========+==========================================+
| qpest                   |       | PEST    | [local, gradient Gauss-Marquardt-        |
|                         |       |         | Levenberg] This script sets the manager  |
|                         |       |         | and agent environment variables for the  |
|                         |       |         | parallelization, and starts the manager  |
|                         |       |         | with "beopest_startmanager.sh" in the    |
|                         |       |         | PEST_MANAGER_QUEUE using 'sbatch'        |
|                         |       |         | (SLURM) or 'qsub' (PBS).  All of the     |
|                         |       |         | other "q*" file names are linked to this |
|                         |       |         | single script.                           |
+-------------------------+-------+---------+------------------------------------------+
| qpest_hp                | X     | PEST_HP | [local, gradient Gauss-Marquardt-        |
|                         |       |         | Levenberg]                               |
+-------------------------+-------+---------+------------------------------------------+
| qpest_cmaes_hp          | X     | PEST_HP | [global, CMA-ES (covariance matrix       |
|                         |       |         | adaptation-evolutionary strategy)] Link  |
|                         |       |         | to 'qpest' script.                       |
+-------------------------+-------+---------+------------------------------------------+
| qrsi_hp                 | X     | PEST_HP | RSI_HP performs a task similar to that   |
|                         |       |         | of PESTPP-IES. Iteratively adjust a set  |
|                         |       |         | of random parameter realizations which   |
|                         |       |         | are samples of the prior parameter       |
|                         |       |         | probability distribution, until they     |
|                         |       |         | constitute samples of the posterior      |
|                         |       |         | parameter probability distribution.      |
+-------------------------+-------+---------+------------------------------------------+
| qpestpp-glm             | X     | PEST++  | local, Gauss-Levenburg-Marquardt         |
+-------------------------+-------+---------+------------------------------------------+
| qpestpp-da              | X     | PEST++  | global, differential evolution           |
+-------------------------+-------+---------+------------------------------------------+
| qpestpp-mou             | X     | PEST++  | single and multiple constrained          |
|                         |       |         | optimization under uncertainty using     |
|                         |       |         | evolutionary heuristics                  |
+-------------------------+-------+---------+------------------------------------------+
| qpestpp-opt             | X     | PEST++  | decision optimization under uncertainty  |
|                         |       |         | using sequential linear programming and  |
|                         |       |         | linearised chance constraints            |
+-------------------------+-------+---------+------------------------------------------+
| qpestpp-sqp             | X     | PEST++  | ensemble-based, constrained, sequential  |
|                         |       |         | quadratic programming                    |
+-------------------------+-------+---------+------------------------------------------+
| qpestpp-ies             | X     | PEST++  | iterative ensemble smoother for          |
|                         |       | utility | calibration-constrained parameter fields |
|                         |       |         | production of a suite of                 |
+-------------------------+-------+---------+------------------------------------------+
| qpestpp-sen             | X     | PEST++  | global sensitivity analysis (Morris and  |
|                         |       | utility | Saltelli)                                |
+-------------------------+-------+---------+------------------------------------------+
| qpestpp-swp             | X     | PEST++  | develops a set of parallelized model     |
|                         |       | utility | runs for any reason                      |
+-------------------------+-------+---------+------------------------------------------+
| beopest_startmanager.sh |       |         | Runs the optimum number of agents using  |
|                         |       |         | "beopest_startagent.sh" in               |
|                         |       |         | PEST_AGENTS_QUEUE using "sbatch" (SLURM) |
|                         |       |         | or "qsub" (PBS).                         |
+-------------------------+-------+---------+------------------------------------------+
| beopest_startagent.sh   |       |         | Starts an agent process that connects to |
|                         |       |         | the manager. The agent runs the model on |
|                         |       |         | the node local to the agent. The model   |
|                         |       |         | has to be specified in the *.pst file as |
|                         |       |         | "beopest_runner composite_model.sh"      |
+-------------------------+-------+---------+------------------------------------------+
| beopest_runner          |       |         | This is a wrapper script for the         |
|                         |       |         | composite model.  It runs the composite  |
|                         |       |         | model on the same node as the agent, but |
|                         |       |         | scheduled through 'sbatch' (SLURM) or    |
|                         |       |         | 'qsub' (PBS) in the PEST_RUNNERS_QUEUE.  |
+-------------------------+-------+---------+------------------------------------------+
| serial_job.sh           |       |         | This is the wrapper script used by the   |
|                         |       |         | "beopest_runner" script to run the       |
|                         |       |         | composite model.                         |
+-------------------------+-------+---------+------------------------------------------+

Installation
============
These scripts expect that some combination of the PEST, PEST_HP, and PEST++
suites of optimizers are installed into a PATH directory.

Copy the five scripts in this distribution into a PATH directory and make
executable using something like the following::

    cp qpest \
       beopest_startmanager.sh \
       beopest_startagent.sh \
       bp_runner \
       serial_job.sh \
       installation/PATH/directory/

    cd installation/PATH/directory/

    chmod a+x \
       qpest \
       beopest_startmanager.sh \
       beopest_startagent.sh \
       bp_runner \
       serial_job.sh

Note that the PEST_HP names use "_" as the separator between parts of the
names.  This is consistent with names in the PEST_HP suite.
If you have the PEST_HP suite installed::

    ln -s qpest qpest_cmaes_hp
    ln -s qpest qpest_hp
    ln -s qpest qrsi_hp

Note that the PEST++ names use "-" as the separator between parts of the
names.  This is consistent with names in the PEST++ suite.
If you have the PEST++ suite installed::

    ln -s qpest qpestpp-glm
    ln -s qpest qpestpp-da
    ln -s qpest qpestpp-ies
    ln -s qpest qpestpp-mou
    ln -s qpest qpestpp-opt
    ln -s qpest qpestpp-sen
    ln -s qpest qpestpp-sqp
    ln -s qpest qpestpp-swp

The `qpest` script uses these link names to set appropriate commands and
options.

To support observation re-referencing you must make two links to the
`beopest_runner` script::

    ln -s beopest_runner r_beopest_runner
    ln -s beopest_runner d_beopest_runner

Help
====
Help is available by running a blank command.  You can also use the "--help"
option for any of the commands.

Modifying the PEST Control File
===============================
The PEST control file (*.pst) needs to be modified to use the new
parallelization framework.  The model command needs to be changed to use the
"beopest_runner" script, for example

This::

    ...
    * model command line
    composite_model.sh
    ...

Needs to be changed to this::

    ...
    * model command line
    beopest_runner composite_model.sh
    ...

The "qpest" script will check this and exit with an error if the model command
line is not set to use the "beopest_runner" script.

Running
=======
The parallel PEST versions are run simply by passing the PEST \*.pst file to
the command, for example: ``qpest_cmaes_hp model_opt.pst``.  There are other
options to control the optimization process, which can be found by running, for
example, ``qpest_cmaes_hp --help``.  Each command has its own options, but they
all share the same options for controlling the parallelization, which are set
in the ``qpest`` script.

Configuration
=============
This process requires three partitions (on SLURM) or queues (on PBS).  One
for the manager that should be limited the maximum number of PEST jobs you
want to run at the same time.  One for the agents and one for the model runs.

    PEST_MANAGER_QUEUE -> on any node, but should be limited to only a few
                         slots to limit the number of simultaneous PEST runs.
    PEST_AGENTS_QUEUE -> run on compute nodes limit to less or equal to
                         number of processor cores.
    PEST_RUNNERS_QUEUE -> run on compute nodes match number of 'pest_agents'
                          on the node.

The agent jobs in ``PEST_AGENTS_QUEUE`` use hardly any resources and just
manage model runs submitted to the ``PEST_RUNNERS_QUEUE`` for the
``PEST_MANAGER_QUEUE`` job.  There has to be the exact same number of
``PEST_AGENTS_QUEUE`` and ``PEST_RUNNERS_QUEUE`` slots on each node.  When
a model is running in ``PEST_RUNNERS_QUEUE`` it will use an entire processor.
These scripts expect to run serial jobs in parallel each with different
parameters.

Set ``PLATFORM`` in qpest to either "slurm" or "pbs".

Set the ``max_agents`` to the maximum number of agents per PEST optimization
run to allow on the cluster.  The ``qpest`` script may set an optimum value
less than this depending on the job.

Example Configuration in `qpest`
================================
::

    PLATFORM="slurm"

    max_agents=150

    PEST_MANAGER_QUEUE=pest.master
    PEST_AGENTS_QUEUE=pest.agents
    PEST_RUNNERS_QUEUE=pest.runners

    # For 'qpest_cmaes_hp' also sets the number of agents to this value but
    # doesn't exceed `max_agents`
    cmaes_population_size=70

SLURM Configuration
===================
Follows is an example `slurm.conf` file::

    # slurm.conf file generated by configurator.html.
    # Put this file on all nodes of your cluster.
    # See the slurm.conf man page for more information.
    #
    ClusterName=cluster
    SlurmctldHost=head
    #SlurmctldHost=
    #
    #DisableRootJobs=NO
    #EnforcePartLimits=NO
    #Epilog=
    #EpilogSlurmctld=
    #FirstJobId=1
    #MaxJobId=67043328
    #GresTypes=
    #GroupUpdateForce=0
    #GroupUpdateTime=600
    #JobFileAppend=0
    #JobRequeue=1
    #JobSubmitPlugins=lua
    #KillOnBadExit=0
    #LaunchType=launch/slurm
    #Licenses=foo*4,bar
    #MailProg=/bin/mail
    #MaxJobCount=10000
    #MaxStepCount=40000
    #MaxTasksPerNode=512
    MpiDefault=none
    #MpiParams=ports=#-#
    #PluginDir=
    #PlugStackConfig=
    #PrivateData=jobs
    ProctrackType=proctrack/cgroup
    #Prolog=
    #PrologFlags=
    #PrologSlurmctld=
    #PropagatePrioProcess=0
    #PropagateResourceLimits=
    #PropagateResourceLimitsExcept=
    #RebootProgram=
    ReturnToService=2
    SlurmctldPidFile=/var/run/slurmctld.pid
    SlurmctldPort=6817
    SlurmdPidFile=/var/run/slurmd.pid
    SlurmdPort=6818
    SlurmdSpoolDir=/var/spool/slurmd
    SlurmUser=slurm
    #SlurmdUser=root
    #SrunEpilog=
    #SrunProlog=
    StateSaveLocation=/var/spool/slurmctld
    SwitchType=switch/none
    #TaskEpilog=
    TaskPlugin=task/affinity,task/cgroup
    #TaskProlog=
    #TopologyPlugin=topology/tree
    #TmpFS=/tmp
    #TrackWCKey=no
    #TreeWidth=
    #UnkillableStepProgram=
    #UsePAM=0
    SlurmctldParameters=enable_configless
    #
    #
    # TIMERS
    #BatchStartTimeout=10
    #CompleteWait=0
    #EpilogMsgTime=2000
    #GetEnvTimeout=2
    #HealthCheckInterval=0
    #HealthCheckProgram=
    InactiveLimit=0
    KillWait=30
    #MessageTimeout=10
    #ResvOverRun=0
    MinJobAge=300
    #OverTimeLimit=0
    SlurmctldTimeout=120
    SlurmdTimeout=300
    #UnkillableStepTimeout=60
    #VSizeFactor=0
    Waittime=0
    #
    #
    # SCHEDULING
    #DefMemPerCPU=0
    #MaxMemPerCPU=0
    #SchedulerTimeSlice=30
    SchedulerType=sched/backfill
    SelectType=select/cons_tres
    SelectTypeParameters=CR_Core
    #
    #
    # JOB PRIORITY
    #PriorityFlags=
    #PriorityType=priority/basic
    PriorityType=priority/multifactor
    #PriorityDecayHalfLife=7-0
    #PriorityCalcPeriod=5
    #PriorityFavorSmall=NO
    #PriorityMaxAge=7-0
    #PriorityUsageResetPeriod=None
    PriorityWeightAge=1
    PriorityWeightFairshare=1
    PriorityWeightJobSize=1
    PriorityWeightPartition=1
    PriorityWeightQOS=1
    #
    #
    # LOGGING AND ACCOUNTING
    #AccountingStorageEnforce=0
    AccountingStorageHost=head
    #AccountingStoragePass=
    #AccountingStoragePort=
    AccountingStorageType=accounting_storage/slurmdbd
    AccountingStorageUser=slurm
    #AccountingStoreFlags=
    #JobCompHost=
    #JobCompLoc=
    #JobCompPass=
    #JobCompPort=
    JobCompType=jobcomp/none
    #JobCompUser=
    #JobContainerType=job_container/none
    JobAcctGatherFrequency=30
    JobAcctGatherType=jobacct_gather/none
    SlurmctldDebug=info
    SlurmctldLogFile=/var/log/slurmctld.log
    SlurmdDebug=info
    SlurmdLogFile=/var/log/slurmd.log
    #SlurmSchedLogFile=
    #SlurmSchedLogLevel=
    #DebugFlags=
    #
    #
    # POWER SAVE SUPPORT FOR IDLE NODES (optional)
    #SuspendProgram=
    #ResumeProgram=
    #SuspendTimeout=
    #ResumeTimeout=
    #ResumeRate=
    #SuspendExcNodes=
    #SuspendExcParts=
    #SuspendRate=
    #SuspendTime=
    #
    # COMPUTE NODES
    NodeName=node[01-08] CPUs=20 Boards=1 SocketsPerBoard=2 CoresPerSocket=10 ThreadsPerCore=1 RealMemory=512000 State=UNKNOWN
    NodeName=head        CPUs=20 Boards=1 SocketsPerBoard=2 CoresPerSocket=10 ThreadsPerCore=1 RealMemory=184320 State=UNKNOWN
    
    PartitionName=allhosts     Default=True  ExclusiveUser=False DisableRootJobs=False RootOnly=False Hidden=False ReqResv=False State=UP OverSubscribe=YES SelectTypeParameters=CR_Core Nodes=node[01-08] MaxTime=INFINITE
    
    PartitionName=pest.master  Default=False ExclusiveUser=False DisableRootJobs=False RootOnly=False Hidden=False ReqResv=False State=UP OverSubscribe=YES SelectTypeParameters=CR_Core Nodes=head
    
    PartitionName=pest.agents  Default=False ExclusiveUser=False DisableRootJobs=False RootOnly=False Hidden=False ReqResv=False State=UP OverSubscribe=YES SelectTypeParameters=CR_Core Nodes=node[01-08] LLN=True
    
    PartitionName=pest.runners Default=False ExclusiveUser=False DisableRootJobs=False RootOnly=False Hidden=False ReqResv=False State=UP OverSubscribe=YES SelectTypeParameters=CR_Core Nodes=node[01-08]
    
    PartitionName=prunners     Default=False ExclusiveUser=False DisableRootJobs=False RootOnly=False Hidden=False ReqResv=False State=UP OverSubscribe=YES SelectTypeParameters=CR_Core Nodes=head DefMemPerCPU=25600

TODO
====
- This system of scripts are untested on PBS, but should work with the
  appropriate configuration.  Testing and documentation for PBS is needed.
- The current system cannot change the number of agents during the
  optimization, similar to how MPI works.  Would be useful to have the system
  adapt to the number of PEST optimization runs and the number of agents per
  run to adapt to cluster load.
