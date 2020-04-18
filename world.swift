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

let UNIVERSE_RADIUS = 1.4e9 * PARSEC
let GALAXY_RADIUS = 1e6 * PARSEC
let SYSTEM_RADIUS = 100 * AU
let PLANET_RADIUS = 1e8 * KM
let MAX_STATION_DISTANCE = 1e6 * KM


////////////////////////////// CONFIG /////////////////////////////////////////

let configString = """
{
    "randomSeed": 3,
    "numGalaxies": 2,
    "maxSystems": 5,
    "maxPlanets": 40,
    "maxMoons": 100,
    "maxAsteroids": 1000000,
    "stationDefaultCapacity": 1000,
    "miningRange": 100.0
}
"""
class Config: Decodable{
    let randomSeed: Int
    let numGalaxies: Int
    let maxSystems: Int
    let maxPlanets: Int
    let maxMoons: Int
    let maxAsteroids: Int
    let stationDefaultCapacity: Double
    let miningRange: Double
}
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

func coordGen(rho_scaling: Double) -> SphericalPoint{
    var rho = Double(random()) / Double(RAND_MAX)
    let rho2 = Double(random()) / Double(RAND_MAX)
    let theta = Double(random()) / Double(RAND_MAX)
    var phi = Double(random()) / Double(RAND_MAX)
    let phi2 = Double(random()) / Double(RAND_MAX)
    phi = (phi - 0.5) * 2 * phi2
    rho = rho * rho2
    return SphericalPoint(rho * rho_scaling, theta * 360, phi * 360)
}

////////////////////////////// CLASSES ////////////////////////////////////////

func toCartesian(_ p: SphericalPoint) -> (Point){
    let x = p.rho * sin(p.phi) * cos(p.theta)
    let y = p.rho * sin(p.phi) * sin(p.theta)
    let z = p.rho * cos(p.theta)
    return Point(x, y, z)
}

func toSpherical(_ p: Point) -> SphericalPoint{
    let rho = sqrt(p.x*p.x+p.y*p.y+p.z*p.z)
    let theta = atan(p.y/p.x)
    let phi = acos(p.z/sqrt(p.x*p.x+p.y*p.y+p.z*p.z))
    return SphericalPoint(rho, theta, phi)
}

struct SphericalPoint{
    var rho: Double
    var theta: Double
    var phi: Double

    init(_ rho: Double, _ theta: Double, _ phi: Double){
        self.rho = rho
        self.theta = theta
        self.phi = phi
    }
}

struct Point{
    var x: Double
    var y: Double
    var z: Double

    init(_ x: Double, _ y: Double, _ z: Double){
        self.x = x
        self.y = y
        self.z = z
    }

    // round each coordinate up to nearest power of 2
    mutating func potimize(){
        x = potimizeDouble(x)
        y = potimizeDouble(y)
        z = potimizeDouble(z)
    }

    func xyz() -> [Double] {
        return [x, y, z]
    }
}

func +(left: Point, right: Point) -> Point {
    return Point(left.x + right.x, left.y + right.y, left.z + right.z)
}

func -(left: Point, right: Point) -> Point {
    return Point(left.x - right.x, left.y - right.y, left.z - right.z)
}

func distance(_ left: Point, _ right: Point) -> Double {
    return sqrt((left.x - right.x) ** 2 + (left.y - right.y) ** 2 + (left.z - right.z) ** 2)
}

precedencegroup ExponentiationPrecedence {
  associativity: left
  higherThan: MultiplicationPrecedence
}
infix operator ** : ExponentiationPrecedence

func ** (num: Double, power: Double) -> Double{
    return pow(num, power)
}

class Uid{
    let id: Int

    static var count: Int = 0
    class func getNewId() -> Int{
        let rax = count
        count += 1
        return rax
    }

    init(){
        self.id = Uid.getNewId()
    }
}

class CelestialObject:Uid{
    var collisionRadius: Double = 0.0
    var position: SphericalPoint = SphericalPoint(0,0,0)
    var positionCartesian: Point = Point(0,0,0)
}

class CargoSpace{
    var capacity: Double = 0

    var minerals: Double = 0 // minerals are used for building ships, stations and heavy machinery
    var gas: Double = 0 // gas is used for fuel, life support and synthetic materials
    var precious: Double = 0 // precious elements are used in electronics and high tech equipment
    var fuel: Double = 0 // used for spaceship propulsion
    var lifeSupport: Double = 0 // keeps living things alive
    var miningDrone: Double = 0 // used to harvest resources from asteroids, planets and moons
    var spareParts: Double = 0 // used to repair all kinds of things
    var weapons: Double = 0 // used to destroy all kinds of things
    var spaceShip: Double = 0 // can fly around in space and carry stuff
    var spaceStation: Double = 0 // conventient place to process resources and build things
    var factory: Double = 0 // turns resources into everything except fuel and life support
    var refinery: Double = 0 // turns gas into fuel and life support

    init(capacity: Double){
        self.capacity = capacity
    }

    func remainingCapacity() -> Double{
        var counter = capacity

        for variable in [
            self.minerals,
            self.gas,
            self.precious,
            self.lifeSupport,
            self.miningDrone,
            self.spareParts,
            self.weapons,
            self.spaceShip,
            self.spaceStation,
            self.factory,
            self.refinery] {
            if(variable < 0) {
                print("!!! negative value of \(variable) detected in cargo space!")
            } else {
                counter -= variable
            }
        }
        if(counter < 0){
            print("!!! cargo space overflow! \(counter) remaining of \(self.capacity) capacity!")
        }
        return counter
    }
}

enum Command{
    case move(SphericalPoint)
    case warp(System)
    case jump(Galaxy)
    case harvest(Asteroid)
    case unload(Station)
    case refuel(Station)
    case attack(Ship)
    case bombard(Station)
}

class Ship:Uid{
    var cargo: CargoSpace
    var owner: String
    var commandQueue: [Command] = []

    var collisionRadius: Double
    var currentSystem: System
    var position: SphericalPoint
    var positionCartesian: Point

    init(owner: String, size: Double, system: System){
        self.owner = owner
        self.cargo = CargoSpace(capacity: size)
        self.collisionRadius = size
        self.currentSystem = system
        self.position = SphericalPoint(0,0,0)
        self.positionCartesian = toCartesian(self.position)
    }

    func move(to: SphericalPoint){
        let fuelRemaining = cargo.fuel
        if(fuelRemaining < 1.0){
            return
        } else {
            cargo.fuel -= 1.0
            self.position = to
            self.positionCartesian = toCartesian(self.position)
        }
    }

    func generateCommands(){
        if(self.cargo.remainingCapacity() < 1.0 || self.cargo.fuel < 2.0){
            let station = self.currentSystem.findNearestStation(to: self.positionCartesian)
            if station == nil{
                return
            }
            self.commandQueue.append(Command.move(station!.position))
            self.commandQueue.append(Command.unload(station!))
            self.commandQueue.append(Command.refuel(station!))
        } else if self.cargo.miningDrone >= 1 {
            let roid = self.currentSystem.findNearestAsteroid(to: self.positionCartesian)
            if roid == nil{
                return
            }
            if distance(self.positionCartesian, roid!.positionCartesian) < config.miningRange{
                self.commandQueue.append(Command.harvest(roid!))
            } else {
                self.commandQueue.append(Command.move(roid!.position))
            }
        }     
    }

    func tick(){
        if(commandQueue.count == 0){
            self.generateCommands()
        }
        if(commandQueue.count > 0){
            let action = commandQueue[0]
            commandQueue.removeFirst()
            switch(action){
            case .move(let toWhere):
                move(to: toWhere)
            case .harvest(let roid):
                if distance(self.positionCartesian, roid.positionCartesian) < config.miningRange{
                    // TODO
                }
//            case .unload:
//            case .refuel:
            default:
                print("command not handled: \(action)")
            }
        } else {
        }
    }
}

class Station:CelestialObject{
    let hold: CargoSpace
    var owner: String = ""

    var minerals: Double = 0
    var gas: Double = 0
    var precious: Double = 0

    init(seed: Int){
        self.hold = CargoSpace(capacity: config.stationDefaultCapacity)
    }

    func proceduralInit(parent: CelestialObject){
        print("Space Station!")
        self.position = coordGen(rho_scaling: MAX_STATION_DISTANCE)
        self.position.rho += self.collisionRadius + parent.collisionRadius
        self.positionCartesian = toCartesian(self.position) + parent.positionCartesian
    }
}

class Asteroid{
    private let randomSeed: Int!
    let id: Int
    
    var collisionRadius: Double = 0.0
    var position: SphericalPoint = SphericalPoint(0,0,0)
    var positionCartesian: Point = Point(0,0,0)

    var minerals: Double = 0
    var gas: Double = 0
    var precious: Double = 0

    init(seed: Int, id: Int){
        self.randomSeed = seed
        self.id = id
    }

    func proceduralInit(parent: System){
        srandom(UInt32(self.randomSeed))
        self.collisionRadius = 10 * KM
        self.position = coordGen(rho_scaling: SYSTEM_RADIUS)
        self.position.rho += self.collisionRadius + parent.collisionRadius
        self.positionCartesian = toCartesian(self.position)

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
        minerals *= 1e3
        gas *= 1e3
        precious *= 1e3
    }
}

class Moon:CelestialObject{
    private let randomSeed: Int
    
    var minerals: Double = 0
    var gas: Double = 0
    var precious: Double = 0

    var stations = [Station]()

    init(seed: Int){
        self.randomSeed = seed
    }

    func proceduralInit(parent: Planet){
        srandom(UInt32(self.randomSeed))
        self.collisionRadius = 1.7e3 * KM
        self.position = coordGen(rho_scaling: PLANET_RADIUS)
        self.position.rho += self.collisionRadius + parent.collisionRadius
        self.positionCartesian = toCartesian(self.position) + parent.positionCartesian
        let numStations = random() % 100 == 0 ? 1 : 0
        for _ in 0..<numStations{
            stations.append(Station(seed: random()))
        }
        for i in 0..<numStations{
            stations[i].proceduralInit(parent: self)
        }

        let type = random()
        if type % 5 > 0{
            minerals = Double(random()) / Double(RAND_MAX)
        }
        if type % 5 < 2{
            gas = Double(random()) / Double(RAND_MAX)
        }
        if type % 2 == 0{
            precious = Double(random()) / Double(RAND_MAX)
        }

        minerals = minerals * 1e7
        gas = gas * 1e7
        precious = precious * 1e5
    }
}

class Planet:CelestialObject{
    private let randomSeed: Int
    
    var minerals: Double = 0
    var gas: Double = 0
    var precious: Double = 0
    
    var moons = [Moon]()
    var stations = [Station]()

    init(seed: Int){
        self.randomSeed = seed
    }

    func proceduralInit(parent: System){
        srandom(UInt32(self.randomSeed))
        self.collisionRadius = 6.4e3 * KM
        self.position = coordGen(rho_scaling: 0.2 * SYSTEM_RADIUS)
        self.position.rho += self.collisionRadius + parent.collisionRadius
        self.positionCartesian = toCartesian(self.position)
        let numMoons = moonQtyGen(max_: config.maxMoons, min_:0)
        let numStations = random() % 10 == 0 ? 1 : 0
        for _ in 0..<numMoons{
            moons.append(Moon(seed: random()))
        }
        for _ in 0..<numStations{
            stations.append(Station(seed: random()))
        }
        for i in 0..<numMoons{
            moons[i].proceduralInit(parent: self)
        }
        for i in 0..<numStations{
            stations[i].proceduralInit(parent: self)
        }

        let type = random()
        if type % 5 > 3{
            minerals = Double(random()) / Double(RAND_MAX)
            precious = Double(random()) / Double(RAND_MAX)
        }
        if type % 5 <= 3{
            gas = Double(random()) / Double(RAND_MAX)
        }

        minerals = minerals * 1e8
        gas = gas * 1e8
        precious = precious * 1e5
    }
}

class System:CelestialObject{
    private let randomSeed: Int
    let spatialTree: HctTree = HctTree(initialSize: SYSTEM_RADIUS)
    
    var planets = [Planet]()
    var asteroids = [Asteroid]()

    init(seed: Int){
        self.randomSeed = seed
    }

    func proceduralInit(parent: Galaxy){
        print("system \(self.id)")
        srandom(UInt32(self.randomSeed))
        self.collisionRadius = 7e5 * KM
        self.position = coordGen(rho_scaling: GALAXY_RADIUS)
        self.position.rho += self.collisionRadius + parent.collisionRadius
        let numPlanets = planetQtyGen(max_: config.maxPlanets, min_:1)
        let numAsteroids = genericQtyGen(max_: config.maxAsteroids, min_:1)
        for _ in 0..<numPlanets{
            planets.append(Planet(seed: random()))
        }
        for i in 0..<numAsteroids{
            asteroids.append(Asteroid(seed: random(), id: i))
        }
        for i in 0..<numPlanets{
            planets[i].proceduralInit(parent: self)
        }
        for i in 0..<numAsteroids{
            asteroids[i].proceduralInit(parent: self)
        }
    }
    
    func stations() -> Array<Station>{
        return planets.flatMap{ $0.stations + $0.moons.flatMap{ $0.stations } }
    }

    // TODO: replace this with an octree version because this is going to be damn slow when the number of ships gets non-trivial
    func findNearestAsteroid(to: Point) -> Asteroid? {
        var nearest: Asteroid? = nil
        for r in asteroids {
            if nearest == nil || distance(to, r.positionCartesian) < distance(to, nearest!.positionCartesian){
                nearest = r
            }
        }
        return nearest
    }
    
    func findNearestStation(to: Point) -> Station? {
        var nearest: Station? = nil
        for s in stations() {
            if nearest == nil || distance(to, s.positionCartesian) < distance(to, nearest!.positionCartesian){
                nearest = s
            }
        }
        return nearest
    }


}

class Galaxy:CelestialObject{
    private let randomSeed: Int
    let spatialTree: HctTree = HctTree(initialSize: GALAXY_RADIUS)
    
    var systems = [System]()

    init(seed: Int){
        self.randomSeed = seed
    }

    func proceduralInit(parent: Universe){
        srandom(UInt32(self.randomSeed))
        self.collisionRadius = 2.2e7 * KM
        self.position = coordGen(rho_scaling: UNIVERSE_RADIUS)
        //let numSystems = genericQtyGen(max_: config.maxSystems, min_:1)
        let numSystems = max(1, random() % config.maxSystems)
        print("spawning \(numSystems) systems")
        for _ in 0..<numSystems{
            systems.append(System(seed: random()))
        }
        print("configuring systems")
        for i in 0..<numSystems{
            systems[i].proceduralInit(parent: self)
        }
        print("\(numSystems) systems ready")
    }
}

class Universe{
    private let randomSeed: Int
    let spatialTree: HctTree = HctTree(initialSize: UNIVERSE_RADIUS)
    var galaxies = [Galaxy]()

    init(seed: Int){
        self.randomSeed = seed
    }

    func proceduralInit(){
        srandom(UInt32(self.randomSeed))
        let numGalaxies = config.numGalaxies
        print("spawning \(numGalaxies) galaxies")
        for _ in 0..<numGalaxies{
            self.galaxies.append(Galaxy(seed: random()))
        }
        print("configuring \(numGalaxies) galaxies")
        for i in 0..<numGalaxies{
            self.galaxies[i].proceduralInit(parent: self)
        }
        print("\(numGalaxies) galaxies ready")
    }

    func allSystems() -> Array<System>{
        return galaxies.flatMap{ $0.systems }
    }

    func allStations() -> Array<Station>{
        return galaxies.flatMap{ $0.systems.flatMap{ $0.planets.flatMap{ $0.stations + $0.moons.flatMap{ $0.stations } } } }
    }
}

