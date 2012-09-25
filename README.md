# Hiera_zookeeper

A backend plugin to Hiera to enable it to reference data from Apache's Zookeeper.
-

##Config Examples for inclusion in hiera.yaml
For a gem like this, config examples make all the difference in getting up and running quickly.
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
  :datadir: "/hiera"
</pre>

##Default Values in accordance with the above sample config

Config[:zookeeper][:server] = localhost:2181
Config[:zookeeper][:datadir] = "/hiera"

##Behavior based on above sample config

Hiera will search the following paths when resolving a key:

  * Make connection to random server in array
  * Search the following:
    * <server>/hiera/one/key
    * <server>/hiera/two/key
    * <server>/hiera/three/key

### Array Searches

Hiera can search through all the tiers in a hierarchy and merge the result into a single
array.  This is used in the hiera-puppet project to replace External Node Classifiers by
creating a Hiera compatible include function.

## Future Enhancements

 * Supporting JSON in addition to YAML.  (Do people want this?) 
 * A webservice that exposes the data

