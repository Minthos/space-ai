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
    "numGalaxies": 1,
    "maxSystems": 1,
    "maxPlanets": 20,
    "maxMoons": 200,
    "maxAsteroids": 100000000
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

func qtyGen(max_: Int, min_: Int) -> Int{
    let a = (random() % max_) / 3
    let b = (random() % max_) / 3
    let c = (random() % max_) / 3
    return min(min_, a * b + c)
}

////////////////////////////// CLASSES ////////////////////////////////////////



class Ship{
//    private let randomSeed: Int!
    let id: Int!

    init(seed: Int, id: Int){
//        self.randomSeed = seed
        self.id = id
    }

    func postInit(){
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

    func postInit(){
//        srandom(UInt32(self.randomSeed))

    }
}

class Asteroid{
    private let randomSeed: Int!
    let id: Int!

    init(seed: Int, id: Int){
        self.randomSeed = seed
        self.id = id
    }

    func postInit(){
        srandom(UInt32(self.randomSeed))
    }
}

class Moon{
    private let randomSeed: Int!
    let id: Int!

    init(seed: Int, id: Int){
        self.randomSeed = seed
        self.id = id
    }

    func postInit(){
        srandom(UInt32(self.randomSeed))

    }
}

class Planet{
    private let randomSeed: Int!
    let id: Int!

    init(seed: Int, id: Int){
        self.randomSeed = seed
        self.id = id
    }

    func postInit(){
        srandom(UInt32(self.randomSeed))

    }
}

class System{
    private let randomSeed: Int!
    let id: Int!

    init(seed: Int, id: Int){
        self.randomSeed = seed
        self.id = id
    }

    func postInit(){
        srandom(UInt32(self.randomSeed))

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

    func postInit(){
        srandom(UInt32(self.randomSeed))
        let numSystems = qtyGen(max_: config.maxSystems, min_:1)
        for i in 0...numSystems{
            systems.append(System(seed: random(), id:i))
        }
        for i in 0...numSystems{
            systems[i].postInit()
        }
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
        let numGalaxies = qtyGen(max_: config.numGalaxies, min_:1)
        for i in 0...numGalaxies{
            self.galaxies.append(Galaxy(seed: random(), id:i))
        }
        for i in 0...numGalaxies{
            self.galaxies[i].postInit()
        }
    }
}

////////////////////////////// INITIALIZATION ////////////////////////////////

print("initializing world with seed: \(config.randomSeed) at time: \(Date()) ");

for _ in 0...3{
    print(random())
    print(Double.random(in: 0...1))
}

////////////////////////////// RUNLOOP ///////////////////////////////////////



