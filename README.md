# Inertia
In-progress top-down 2D racing game with realistic physics & car customization. 

Built completely in Godot 4 using GDScript.

I’m envisioning 5 primary components as the pillars of the gameplay, in order of priority:

## Physics
Realistic: uses real equations & simulates certain aspects in a 3D way
Fun and responsive: should feel fast, quick to react, enjoyable to just drive around
Extensible & organized: code should be clear, concise, well commented and easy to change

## Multiplayer
Need to decide on how this will work. I’m thinking peer to peer using physics-based prediction and replication over Godot’s RPC network layer. Should consider cloud-based solutions, but likely not feasible.

## AI
Need at least simple racetrack AI that will be competitive with the player. They need to not cheat, and use all of the same inputs that the player does. This will be very difficult & require a lot of research.

Need to also consider AI if I go down the road of open city environments. Will need simple traffic AI, possibly some street racers as well that go through the city.

## Environment
Many questions here. Definitely want racetracks, what about a city environment? Can I vectorize & chunk satellite images maybe? A large world to race around in and explore would be amazing, and very fun to make as long as I can find ways not to manually design the visuals of everything.

## Customization
Probably the simplest pillar, but I want extensive car customization and personalization. Or at least as extensive as I can make it in a 2D game. I want players to change color, aero, do engine swaps, change exhaust sound, suspension setup, body kits, stuff like that.
