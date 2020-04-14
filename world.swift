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
    "numSystems": 1,
    "numPlanets": 8
}
"""
class Config: Decodable{
    let randomSeed: UInt32
    let numGalaxies: Int
    let numSystems: Int
    let numPlanets: Int
}
print("reading config")
let configObject = try!JSONDecoder().decode(Config.self, from:configString.data(using: .utf8)!)

////////////////////////////// CLASSES ////////////////////////////////////////

class System{
    private let randomSeed: UInt32!

    init(seed: UInt32){
        self.randomSeed = seed
    }

    func postinit(){
        srandom(self.randomSeed)

    }
}

////////////////////////////// INITIALIZATION ////////////////////////////////

print("initializing world with seed: \(configObject.randomSeed) at time: \(Date()) ");

for _ in 0...3{
    print(random())
    print(Double.random(in: 0...1))
}

////////////////////////////// RUNLOOP ///////////////////////////////////////



