# Systems Operations Environment

A two-subnet Linux and Windows environment built as code, used to practice
production operations work: routing between subnets, SSH and firewall
configuration, scheduled backups, versioned software deployment with rollback,
monitoring and alerting, and incident handling. Every failure in the incidents
folder was created on purpose and worked to root cause.

## Layout

(network diagram and address plan go here)

## How to run

    vagrant up

Checkpoints: cross-subnet ping, SSH to the backup server on port 2222 with
key auth, a completed rsync run.

## Incidents

(one line per incident, linking to the write-up)

## What I learned

(filled in at the end)