////////////////////////////// COPYRIGHT //////////////////////////////////////
// Copyright 2020 Espen Overaae. All rights reserved.
// 


////////////////////////////// IMPORTS ////////////////////////////////////////
import Foundation
import Glibc

let PARSEC = 3.086e16
let LY = 9.461e15
let AU = 1.496e11
let KM = 1e3

////////////////////////////// CONFIG /////////////////////////////////////////

let configString = """
{
    "randomSeed": 3,
    "numGalaxies": 2,
    "maxSystems": 5,
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

func coordGen(rho_scaling: Double) -> (Double, Double, Double){
    var rho = Double(random()) / Double(RAND_MAX)
    let rho2 = Double(random()) / Double(RAND_MAX)
    let theta = Double(random()) / Double(RAND_MAX)
    var phi = Double(random()) / Double(RAND_MAX)
    let phi2 = Double(random()) / Double(RAND_MAX)
    phi = (phi - 0.5) * 2 * phi2
    rho = rho * rho2
    return (rho * rho_scaling, theta * 360, phi * 360)
}

////////////////////////////// CLASSES ////////////////////////////////////////

class Ship{
    let id: Int!

    var rho: Double = 0
    var theta: Double = 0
    var phi: Double = 0

    init(seed: Int, id: Int){
        self.id = id
    }

    func postInit(){
    }
}

class Station{
    let id: Int!

    var rho: Double = 0
    var theta: Double = 0
    var phi: Double = 0

    init(seed: Int, id: Int){
        self.id = id
    }

    func postInit(){
        print("Space Station!")
        (self.rho, self.theta, self.phi) = coordGen(rho_scaling: 1e6 * KM)
    }
}

class Asteroid{
    private let randomSeed: Int!
    let id: Int!

    var rho: Double = 0
    var theta: Double = 0
    var phi: Double = 0

    var minerals: Double = 0
    var gas: Double = 0
    var precious: Double = 0

    init(seed: Int, id: Int){
        self.randomSeed = seed
        self.id = id
    }

    func postInit(){
        srandom(UInt32(self.randomSeed))
        
        (self.rho, self.theta, self.phi) = coordGen(rho_scaling: 100 * AU)

        let type = random()
        if type % 5 > 0{
            minerals = Double(random()) / Double(RAND_MAX)
        }
        if type % 5 < 3{
            gas = Double(random()) / Double(RAND_MAX)
        }
        if type % 16 == 0{
            precious = Double(random()) / Double(RAND_MAX)
        }
    }
}

class Moon{
    private let randomSeed: Int!
    let id: Int!
    
    var rho: Double = 0
    var theta: Double = 0
    var phi: Double = 0

    var stations = [Station]()

    init(seed: Int, id: Int){
        self.randomSeed = seed
        self.id = id
    }

    func postInit(){
        srandom(UInt32(self.randomSeed))
        (self.rho, self.theta, self.phi) = coordGen(rho_scaling: 1e8 * KM)
        let numStations = random() % 100 == 0 ? 1 : 0
        for i in 0..<numStations{
            stations.append(Station(seed: random(), id:i))
        }
        for i in 0..<numStations{
            stations[i].postInit()
        }

    }
}

class Planet{
    private let randomSeed: Int!
    let id: Int!
    
    var rho: Double = 0
    var theta: Double = 0
    var phi: Double = 0
    
    var moons = [Moon]()
    var stations = [Station]()

    init(seed: Int, id: Int){
        self.randomSeed = seed
        self.id = id
    }

    func postInit(){
        srandom(UInt32(self.randomSeed))
        (self.rho, self.theta, self.phi) = coordGen(rho_scaling: 20 * AU)
        let numMoons = moonQtyGen(max_: config.maxMoons, min_:0)
        let numStations = random() % 10 == 0 ? 1 : 0
        for i in 0..<numMoons{
            moons.append(Moon(seed: random(), id:i))
        }
        for i in 0..<numStations{
            stations.append(Station(seed: random(), id:i))
        }
        for i in 0..<numMoons{
            moons[i].postInit()
        }
        for i in 0..<numStations{
            stations[i].postInit()
        }

    }
}

class System{
    private let randomSeed: Int!
    let id: Int
    
    var rho: Double = 0
    var theta: Double = 0
    var phi: Double = 0
    
    var planets = [Planet]()
    var asteroids = [Asteroid]()

    init(seed: Int, id: Int){
        self.randomSeed = seed
        self.id = id
    }

    func postInit(){
        print("system \(self.id)")
        srandom(UInt32(self.randomSeed))
        (self.rho, self.theta, self.phi) = coordGen(rho_scaling: 1.0e6 * PARSEC)
        let numPlanets = planetQtyGen(max_: config.maxPlanets, min_:1)
        let numAsteroids = genericQtyGen(max_: config.maxAsteroids, min_:1)
        for i in 0..<numPlanets{
            planets.append(Planet(seed: random(), id:i))
        }
        for i in 0..<numAsteroids{
            asteroids.append(Asteroid(seed: random(), id:i))
        }
        for i in 0..<numPlanets{
            planets[i].postInit()
        }
        for i in 0..<numAsteroids{
            asteroids[i].postInit()
        }
    }
}

class Galaxy{
    private let randomSeed: Int!
    let id: Int!
    
    var rho: Double = 0
    var theta: Double = 0
    var phi: Double = 0
    
    var systems = [System]()

    init(seed: Int, id: Int){
        self.randomSeed = seed
        self.id = id
    }

    func postInit(){
        srandom(UInt32(self.randomSeed))
        (self.rho, self.theta, self.phi) = coordGen(rho_scaling: 1.4e9 * PARSEC)
        //let numSystems = genericQtyGen(max_: config.maxSystems, min_:1)
        let numSystems = max(1, random() % config.maxSystems)
        print("spawning \(numSystems) systems")
        for i in 0..<numSystems{
            systems.append(System(seed: random(), id:i))
        }
        print("configuring systems")
        for i in 0..<numSystems{
            systems[i].postInit()
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

    func postInit(){
        srandom(UInt32(self.randomSeed))
        let numGalaxies = config.numGalaxies
        print("spawning \(numGalaxies) galaxies")
        for i in 0..<numGalaxies{
            self.galaxies.append(Galaxy(seed: random(), id:i))
        }
        print("configuring \(numGalaxies) galaxies")
        for i in 0..<numGalaxies{
            self.galaxies[i].postInit()
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
world.postInit()

////////////////////////////// RUNLOOP ///////////////////////////////////////

//while true {
//    print("zzz...")
//    sleep(1);
//}

