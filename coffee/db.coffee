Datastore = require 'nedb'
config    = require '../settings'
_         = require 'underscore-contrib'

# Generic responses
generic = [
  'wags his tail'
  'Woof!'
  'gives you the ol\' puppy eyes'
  'rolls around'
  'licks your face'
  'chases his tail'
  'sneezes'
  'steals your slippers'
]

bored = [
  'pees on the floor'
  'scratches at the door'
  'brings you a ball'
  'brings you a leash'
  'Awwwoooooooooww!'
  'falls asleep'
]

# Targeted responses
reactions = [
  {
    actions: ['punt', 'kick', 'slap', 'punch', 'hit', 'slap', 'pinch'],
    response: ['barks', 'growls', 'wimpers', 'runs away', 'grrrrrrrr', 'Awooooooooooow!']
  },

  {
    actions: ['help', 'what'],
    response: ['looks at you quizzically']
  },

  {
    actions: ['cute', 'adorable', 'cuddly'],
    response: ['prances around', 'wags his tail']
  },

  {
    actions: ['pet', 'scratch', 'play', 'fetch', 'ball', 'feed', 'treat', 'walk'],
    response: generic
  },
]

