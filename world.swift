////////////////////////////// COPYRIGHT //////////////////////////////////////
// Copyright 2020 Espen Overaae. All rights reserved.
// Noncommercial use/modification/distribution permitted until further notice.


////////////////////////////// IMPORTS ////////////////////////////////////////
import Foundation
import Glibc

////////////////////////////// CONFIG /////////////////////////////////////////

let configString = """
{
    "randomSeed": 1,
    "numGalaxies": 2,
    "maxSystems": 10,
    "maxPlanets": 40,
    "maxMoons": 100,
    "maxAsteroids": 1000000
}
"""
class Config: Decodable{
    let randomSeed: Int
    let numGalaxies: Int
    let maxSystems: Int
    let maxPlanets: Int
    let maxMoons: Int
    let maxAsteroids: Int
}
print("reading config")
let config = try!JSONDecoder().decode(Config.self, from:configString.data(using: .utf8)!)

func planetQtyGen(max_: Int, min_: Int) -> Int{
    let a = (random() % max_)
    let b = (random() % max_)
    return max(min_, (a * b) / max_)
}

func moonQtyGen(max_: Int, min_: Int) -> Int{
    let a = (random() % max_)
    let b = (random() % max_)
    let c = (random() % max_)
    let d = (random() % max_)
    return max(min_, ((((a * b) / max_) * ((d * c) / max_)) / max_))
}

func genericQtyGen(max_: Int, min_: Int) -> Int{
    let a = (random() % max_)
    let b = (random() % max_)
    return max(min_, (a * b) / max_)
}

////////////////////////////// CLASSES ////////////////////////////////////////

class Ship{
//    private let randomSeed: Int!
    let id: Int!

    init(seed: Int, id: Int){
//        self.randomSeed = seed
        self.id = id
    }

    func postPostInit(){
//        srandom(UInt32(self.randomSeed))

    }
}

class Station{
//    private let randomSeed: Int!
    let id: Int!

    init(seed: Int, id: Int){
        self.id = id
//        self.randomSeed = seed
    }

    func postPostInit(){
//        srandom(UInt32(self.randomSeed))
        print("Space Station!")
    }
}

class Asteroid{
    private let randomSeed: Int!
    let id: Int!

    init(seed: Int, id: Int){
        self.randomSeed = seed
        self.id = id
    }

    func postPostInit(){
        srandom(UInt32(self.randomSeed))
    }
}

class Moon{
    private let randomSeed: Int!
    let id: Int!
    var stations = [Station]()

    init(seed: Int, id: Int){
        self.randomSeed = seed
        self.id = id
    }

    func postPostInit(){
        srandom(UInt32(self.randomSeed))
        let numStations = random() % 100 == 0 ? 1 : 0
        for i in 0..<numStations{
            stations.append(Station(seed: random(), id:i))
        }
        for i in 0..<numStations{
            stations[i].postPostInit()
        }

    }
}

class Planet{
    private let randomSeed: Int!
    let id: Int!
    var moons = [Moon]()
    var stations = [Station]()

    init(seed: Int, id: Int){
        self.randomSeed = seed
        self.id = id
    }

    func postPostInit(){
        srandom(UInt32(self.randomSeed))
        let numMoons = moonQtyGen(max_: config.maxMoons, min_:0)
        let numStations = random() % 10 == 0 ? 1 : 0
        if numMoons > 0{
            print("spawning \(numMoons) moons")
        }
        for i in 0..<numMoons{
            moons.append(Moon(seed: random(), id:i))
        }
        for i in 0..<numMoons{
            moons[i].postPostInit()
        }
        for i in 0..<numStations{
            stations.append(Station(seed: random(), id:i))
        }
        for i in 0..<numStations{
            stations[i].postPostInit()
        }

    }
}

class System{
    private let randomSeed: Int!
    let id: Int
    var planets = [Planet]()
    var asteroids = [Asteroid]()

    init(seed: Int, id: Int){
        self.randomSeed = seed
        self.id = id
    }

    func postPostInit(){
        print("system \(self.id)")
        srandom(UInt32(self.randomSeed))
        let numPlanets = planetQtyGen(max_: config.maxPlanets, min_:1)
        let numAsteroids = genericQtyGen(max_: config.maxAsteroids, min_:1)
        print("spawning \(numPlanets) planets")
        for i in 0..<numPlanets{
            planets.append(Planet(seed: random(), id:i))
        }
        for i in 0..<numPlanets{
            planets[i].postPostInit()
        }
        print("\(numPlanets) planets ready")
        print("spawning \(numAsteroids) asteroids")
        for i in 0..<numAsteroids{
            asteroids.append(Asteroid(seed: random(), id:i))
        }
        for i in 0..<numAsteroids{
            asteroids[i].postPostInit()
        }
        print("\(numAsteroids) asteroids ready")
    }
}

class Galaxy{
    private let randomSeed: Int!
    let id: Int!
    var systems = [System]()

    init(seed: Int, id: Int){
        self.randomSeed = seed
        self.id = id
    }

    func postPostInit(){
        srandom(UInt32(self.randomSeed))
        let numSystems = genericQtyGen(max_: config.maxSystems, min_:1)
        print("spawning \(numSystems) systems")
        for i in 0..<numSystems{
            systems.append(System(seed: random(), id:i))
        }
        print("configuring systems")
        for i in 0..<numSystems{
            systems[i].postPostInit()
        }
        print("\(numSystems) systems ready")
    }
}

class Universe{
    private let randomSeed: Int!
    var galaxies = [Galaxy]()

    init(seed: Int){
        self.randomSeed = seed
    }

    func postPostInit(){
        srandom(UInt32(self.randomSeed))
        let numGalaxies = config.numGalaxies
        print("spawning \(numGalaxies) galaxies")
        for i in 0..<numGalaxies{
            self.galaxies.append(Galaxy(seed: random(), id:i))
        }
        print("configuring \(numGalaxies) galaxies")
        for i in 0..<numGalaxies{
            self.galaxies[i].postPostInit()
        }
        print("\(numGalaxies) galaxies ready")
    }
}

////////////////////////////// INITIALIZATION ////////////////////////////////


//print("initializing world with seed: \(config.randomSeed) at time: \(Date()) ");
//let world = Universe(seed: config.randomSeed)

var seed = config.randomSeed
if(CommandLine.arguments.count > 1){
    seed = Int(CommandLine.arguments[1]) ?? config.randomSeed
}
print("initializing world with seed: \(seed) at time: \(Date()) ");
let world = Universe(seed: seed)
world.postPostInit()

////////////////////////////// RUNLOOP ///////////////////////////////////////



