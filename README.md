#hiera_zookeeper

A backend plugin to Hiera to enable it to reference data from Zookeeper.

##Config Examples for inclusion in hiera.yaml
For a gem like this, hiera.yaml config examples make all the difference in getting up and running quickly.
Here they are:

<pre>
:backends:
  - zookeeper
:hierarchy:
  - one
  - two
  - three
:zookeeper:
  :server:
    - server1:2181
    - server2:2181
  :timeout: 1
  :datadir: "/hiera"
</pre>

##Default Values
These are the values used by hiera_zookeeper if not specified in hiera.yaml:

Config[:zookeeper][:server] = localhost:2181<br />
Config[:zookeeper][:datadir] = "/hiera"<br />
Config[:zookeeper][:timeout] = 1

##Behavior based on above sample config

Hiera will search the following paths when resolving a key:

  * Make connection to random server in array (N)
  * Search the following:
    1. serverN:2181/hiera/one/key
    2. serverN:2181/hiera/two/key
    3. serverN:2181/hiera/three/key

##Future Enhancements

 * Supporting JSON in addition to YAML.  (Would people want this?) 
