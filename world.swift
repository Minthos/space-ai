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

    //"maxAsteroids": 1000000

let configString = """
{
    "randomSeed": 3,
    "numGalaxies": 2,
    "maxSystems": 5,
    "maxPlanets": 40,
    "maxMoons": 100,
    "asteroidResourceMultiplier": 1e2,
    "maxAsteroids": 1000000,
    "stationDefaultCapacity": 10000,
    "stationDefaultModuleCapacity": 1000,
    "fuelConsumption": 3e-9,
    "movementRange": 50.0,
    "miningRange": 100.0,
    "dockingRange": 100.0,
    "productionRate": 0.1,
    "researchRate": 0.01,
    "shipCost": {"minerals": 0.7, "gas": 0.2, "precious": 0.1},
    "droneCost": {"minerals": 0.7, "gas": 0.2, "precious": 0.1},
    "stationCost": {"minerals": 0.95, "gas": 0.05, "precious": 0},
    "factoryCost": {"minerals": 0.9, "gas": 0.08, "precious": 0.02},
    "refineryCost": {"minerals": 0.9, "gas": 0.08, "precious": 0.02},
    "weaponCost": {"minerals": 0.5, "gas": 0.3, "precious": 0.2},
    "labCost": {"minerals": 0.5, "gas": 0.3, "precious": 0.2}
}
"""
struct ResourceAmount: Decodable{
    var minerals: Double
    var gas: Double
    var precious: Double

    init(_ minerals: Double, _ gas: Double, _ precious: Double){
        self.minerals = minerals
        self.gas = gas
        self.precious = precious
    }

    func values() -> [Double] {
        return [minerals, gas, precious]
    }
}

class Config: Decodable{
    let randomSeed: Int
    let numGalaxies: Int
    let maxSystems: Int
    let maxPlanets: Int
    let maxMoons: Int
    let asteroidResourceMultiplier: Double
    let maxAsteroids: Int
    let stationDefaultCapacity: Double
    let stationDefaultModuleCapacity: Double
    let fuelConsumption: Double
    let movementRange: Double
    let miningRange: Double
    let dockingRange: Double
    let productionRate: Double
    let researchRate: Double
    let shipCost: ResourceAmount
    let droneCost: ResourceAmount
    let stationCost: ResourceAmount
    let factoryCost: ResourceAmount
    let refineryCost: ResourceAmount
    let weaponCost: ResourceAmount
    let labCost: ResourceAmount
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
    
    var pretty: String {
        return "(rho: \(rho.pretty), theta: \(theta.pretty), phi: \(phi.pretty))"
    }
    
    var scientific: String {
        return "SphericalPoint(rho: \(rho.scientific), theta: \(theta.scientific), phi: \(phi.scientific))"
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
    
    var pretty: String {
        return "(\(x.pretty), \(y.pretty), \(z.pretty))"
    }
    
    var scientific: String {
        return "Point(x: \(x.scientific), y: \(y.scientific), z: \(z.scientific))"
    }
}

postfix func --(value: inout Int) {
    value -= 1
}

postfix func ++(value: inout Int) {
    value += 1
}

func /(left: ResourceAmount, right: Double) -> ResourceAmount {
    return ResourceAmount(left.minerals / right, left.gas / right, left.precious / right)
}

func *(left: ResourceAmount, right: Double) -> ResourceAmount {
    return ResourceAmount(left.minerals * right, left.gas * right, left.precious * right)
}

func /(left: ResourceAmount, right: ResourceAmount) -> ResourceAmount {
    return ResourceAmount(left.minerals / right.minerals, left.gas / right.gas, left.precious / right.precious)
}

func *(left: ResourceAmount, right: ResourceAmount) -> ResourceAmount {
    return ResourceAmount(left.minerals * right.minerals, left.gas * right.gas, left.precious * right.precious)
}

func -(left: ResourceAmount, right: ResourceAmount) -> ResourceAmount {
    return ResourceAmount(left.minerals - right.minerals, left.gas - right.gas, left.precious - right.precious)
}

func +(left: ResourceAmount, right: ResourceAmount) -> ResourceAmount {
    return ResourceAmount(left.minerals + right.minerals, left.gas + right.gas, left.precious + right.precious)
}

func <(left: ResourceAmount, right: ResourceAmount) -> Bool {
    return (left.minerals < right.minerals || left.gas < right.gas || left.precious < right.precious)
}

func >(left: ResourceAmount, right: ResourceAmount) -> Bool {
    return (left.minerals > right.minerals && left.gas > right.gas && left.precious > right.precious)
}

func *(left: Point, right: Double) -> Point {
    return Point(left.x * right, left.y * right, left.z * right)
}

func +(left: Point, right: Point) -> Point {
    return Point(left.x + right.x, left.y + right.y, left.z + right.z)
}

func -(left: Point, right: Point) -> Point {
    return Point(left.x - right.x, left.y - right.y, left.z - right.z)
}

func +(left: Point, right: Double) -> Point {
    return Point(left.x + right, left.y + right, left.z + right)
}

func -(left: Point, right: Double) -> Point {
    return Point(left.x - right, left.y - right, left.z - right)
}

func ==(left: Point, right: Point) -> Bool {
    return left.x == right.x && left.y == right.y && left.z == right.z
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

extension Double {
    static var epsilon: Double { return Double.leastNonzeroMagnitude }
}

extension Formatter {
    static let scientific: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .scientific
        formatter.positiveFormat = "0.###E+0"
        formatter.exponentSymbol = "e"
        return formatter
    }()
}

extension Numeric {
    var scientific: String {
        return Formatter.scientific.string(for: self) ?? ""
    }
}

extension Double {
    var pretty: String {
        if(self < 0.001){
            return self.scientific
        } else if(self < 1){
            return String(format: "%.4f", self)
        }  else if(self < 1000) {
            return String(format: "%.2f", self)
        }  else if(self < 1e6) {
            return String(format: "%.2fk", self/1e3)
        }  else if(self < 1e9) {
            return String(format: "%.2fM", self/1e6)
        }  else if(self < 1e12) {
            return String(format: "%.2fG", self/1e9)
        }  else if(self < 1e15) {
            return String(format: "%.2fT", self/1e12)
        } else {
            return self.scientific
        }
    }
}

extension Sequence where Element: AdditiveArithmetic {
    func sum() -> Element { reduce(.zero, +) }
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
    var netMass: Double { get { if(dirty){ updateMass() }; return __mass } }
    var grossMass: Double { get { return 0.5 * capacity + netMass } }
    var dirty = false

    private var __mass: Double = 0
    
    var contents: [String:Double] = [
        "minerals": 0, // minerals are used for building ships, stations and heavy machinery
        "gas": 0, // gas is used for fuel, life support and synthetic materials
        "precious": 0, // precious elements are used in electronics and high tech equipment
        "fuel": 0, // used for spaceship propulsion
        "lifeSupport": 0, // keeps living things alive
        "miningDrone": 0, // used to harvest resources from asteroids, planets and moons
        "spareParts": 0, // used to repair all kinds of things
        "weapons": 0, // used to destroy all kinds of things
        "propulsion": 0, // spaceships use this to move around
        "spaceShip": 0, // can fly around in space and carry stuff
        "spaceStation": 0, // conventient place to process resources and build things
        "factory": 0, // turns resources into everything except fuel and life support
        "refinery": 0, // turns gas into fuel and life support
        "researchLab": 0 // knowledge is power
    ]

    func updateMass() {
        self.__mass = self.contents.values.sum()
        self.dirty = false
    }
    
    var resources: ResourceAmount {
        get { return ResourceAmount(self.minerals, self.gas, self.precious) }
        set {   self.minerals = newValue.minerals
                self.gas = newValue.gas
                self.precious = newValue.precious
                self.dirty = true }
    }

    var fuel: Double {
        get { return contents["fuel"]! }
        set { contents["fuel"] = newValue; dirty = true }
    }

    var minerals: Double {
        get { return contents["minerals"]! }
        set { contents["minerals"] = newValue; dirty = true }
    }

    var gas: Double {
        get { return contents["gas"]! }
        set { contents["gas"] = newValue; dirty = true }
    }

    var precious: Double {
        get { return contents["precious"]! }
        set { contents["precious"] = newValue; dirty = true }
    }

    var lifeSupport: Double {
        get { return contents["lifeSupport"]! }
        set { contents["lifeSupport"] = newValue; dirty = true }
    }

    var miningDrone: Double {
        get { return contents["miningDrone"]! }
        set { contents["miningDrone"] = newValue; dirty = true }
    }

    var spareParts: Double {
        get { return contents["spareParts"]! }
        set { contents["spareParts"] = newValue; dirty = true }
    }

    var weapons: Double {
        get { return contents["weapons"]! }
        set { contents["weapons"] = newValue; dirty = true }
    }

    var propulsion: Double {
        get { return contents["propulsion"]! }
        set { contents["propulsion"] = newValue; dirty = true }
    }

    var spaceShip: Double {
        get { return contents["spaceShip"]! }
        set { contents["spaceShip"] = newValue; dirty = true }
    }

    var spaceStation: Double {
        get { return contents["spaceStation"]! }
        set { contents["spaceStation"] = newValue; dirty = true }
    }
    
    var factory: Double {
        get { return contents["factory"]! }
        set { contents["factory"] = newValue; dirty = true }
    }

    var refinery: Double {
        get { return contents["refinery"]! }
        set { contents["refinery"] = newValue; dirty = true }
    }
        
    var researchLab: Double {
        get { return contents["researchLab"]! }
        set { contents["researchLab"] = newValue; dirty = true }
    }

    init(capacity: Double){
        self.capacity = capacity
    }

    func transfer(items: [String], to: CargoSpace) -> Bool{
        if(to.remainingCapacity() < items.map( { contents[$0]! } ).sum()){
            print("Error! Cargo space overflow when attempting to transfer \(items) to \(to.pretty)")
            return false
        }
        for key in items{
            to.contents[key]! += self.contents[key]!
            self.contents[key] = 0
        }
        to.dirty = true
        self.dirty = true
        return true
    }

    func remainingCapacity() -> Double{
        return capacity - netMass
    }

    var pretty: String{ get {
        let pairs = self.contents.filter({ $0.value > 0 }).sorted(by: { $0.0 < $1.0 })
        let output = "[" + pairs.map({ "\($0.key): \($0.value.pretty)" }).joined(separator: ", ") + "]"
        return output
    }}
}

enum ShipCommand{
    case move(Point)
    case warp(System)
    case jump(Galaxy)
    case harvest(Asteroid)
    case unload(Station)
    case refuel(Station, targetAmount: Double)
    case attack(Ship)
    case bombard(Station)
    case nothing
}

class Ship:Uid{
    var cargo: CargoSpace
    var modules: CargoSpace
    var owner: String
    var commandQueue: [ShipCommand] = []
    var grossMass: Double { get { 
        return self.cargo.grossMass + self.modules.grossMass
    } }
    var range: Double { get { return config.movementRange * 10 * AU * self.modules.propulsion / grossMass } }
    var fuelMovingAverage = 0.0
    var stuck: Int = 0
    var lastMinedLocation: Point? = nil

    var collisionRadius: Double
    var currentSystem: System
    var position: SphericalPoint
    var positionCartesian: Point

    init(owner: String, size: Double, positionCartesian:Point, system: System){
        self.owner = owner
        self.cargo = CargoSpace(capacity: size)
        self.modules = CargoSpace(capacity: (size * 0.5).rounded())
        self.collisionRadius = sqrt(size)
        self.currentSystem = system
        self.positionCartesian = positionCartesian
        self.position = toSpherical(positionCartesian)

        self.modules.miningDrone = 1
        self.modules.propulsion = (self.modules.remainingCapacity() * 0.5)
    }

    func move(to: Point){
        let mass = self.grossMass
        let maxRange = range
        let inaccuracy = min(config.miningRange, config.dockingRange) * 0.5
        let offset = SphericalPoint(inaccuracy * Double(random()) / Double(RAND_MAX),
                                    Double(random()) / Double(RAND_MAX),
                                    Double(random()) / Double(RAND_MAX))
        let destination = to + toCartesian(offset)
        let dist = distance(self.positionCartesian, to)
        if(dist > maxRange){
            print("Error! insufficient movement range: \(maxRange.pretty) of \(dist.pretty)")
            stuck++
            return
        }
        let fuelCost = sqrt(dist) * mass * config.fuelConsumption
        let fuelRemaining = cargo.fuel
        if(fuelRemaining < fuelCost){
            print("Error! ship is out of fuel! has \(fuelRemaining.pretty) of \(fuelCost.pretty) required")
            stuck++
            return
        } else {
            cargo.fuel -= fuelCost
            currentSystem.shipsRegistry.relocate(item: self, from: self.positionCartesian, to: destination)
            self.positionCartesian = destination
            self.position = toSpherical(self.positionCartesian)
            stuck = 0
        }
    }

    func harvest(_ roid: Asteroid){
        if distance(self.positionCartesian, roid.positionCartesian) < config.miningRange{
            let availableSpace = self.cargo.remainingCapacity()
            let mineableResources = roid.minerals + roid.gas + roid.precious
            if(availableSpace <= Double.epsilon || mineableResources <= 3 * Double.epsilon){
                return
            }
            let fractionToMine = min(1, (availableSpace - 1e-12) / mineableResources)
            let mineMinerals = roid.minerals * fractionToMine
            let mineGas = roid.gas * fractionToMine
            let minePrecious = roid.precious * fractionToMine
            self.cargo.minerals += mineMinerals
            roid.minerals -= mineMinerals
            self.cargo.gas += mineGas
            roid.gas -= mineGas
            self.cargo.precious += minePrecious
            roid.precious -= minePrecious
            stuck = 0

            if(fractionToMine == 1){
                self.currentSystem.depleteAsteroid(roid)
            }
        } else {
            print("Error! out of mining range")
            stuck++
        }
    }

    func unload(_ station: Station){
        if(self.cargo.remainingCapacity() * 5 > cargo.capacity){
            print("ship \(id) unloading with \(cargo.remainingCapacity().pretty) of \(cargo.capacity.pretty) capacity left")
        }
        if distance(self.positionCartesian, station.positionCartesian) < config.dockingRange{
            if self.cargo.transfer(items: ["minerals", "gas", "precious"], to: station.hold){
                stuck = 0
            }
            else{
                stuck++
            }
        }
        else {
            print("Error! out of docking range for unload")
            //print("ship position: \(self.position.pretty)")
            //print("cartesian: \(self.positionCartesian.pretty)")
            //print("station position: \(station.position.pretty)")
            //print("cartesian: \(station.positionCartesian.pretty)")
            stuck++
        }
    }

    func refuel(_ station: Station, targetAmount: Double){
        if distance(self.positionCartesian, station.positionCartesian) < config.dockingRange{
            let amount = min(station.hold.fuel, self.cargo.remainingCapacity(), (targetAmount - self.cargo.fuel))
            station.hold.fuel -= amount
            self.cargo.fuel += amount
            if(self.cargo.fuel + 0.01 < targetAmount){
                print("Error! refueling failed! station fuel level: \(station.hold.fuel.pretty), cargo capacity: \(self.cargo.remainingCapacity().pretty)")
                print("ship: \(self.cargo.pretty)")
                print("station: \(station.hold.pretty)")
                print("modules: \(station.modules.pretty)")
                stuck++
            } else {
                stuck = 0
            }
        }
        else {
            print("Error! out of docking range for refuel")
            stuck++
        }
    }

    // return value: can make it in one tick
    func plotMove(to: Point) -> Bool {
        var destination = to
        let dist = distance(to, destination)
        let r = self.range
        if(dist > r){
            let fraction = dist / r
            let remainder = 1 - fraction
            destination = self.positionCartesian * remainder + destination * fraction
            self.commandQueue.append(ShipCommand.move(destination))
            return false
        }
        self.commandQueue.append(ShipCommand.move(destination))
        return true
    }

    func generateCommands(){
        // TODO: "weight" is an outdated concept, grossMass would be preferred but the constants need to be tweaked
        let weight = self.cargo.capacity * 0.1
        if(self.cargo.remainingCapacity() < 1.0 || self.cargo.fuel < 2.0 * weight){
            var stationCandidates = self.currentSystem.nearbyStations(to: self.positionCartesian)
            if(distance(stationCandidates[0].positionCartesian, self.positionCartesian) > config.dockingRange){
                stationCandidates.shuffle()
            }
            var station: Station? = nil
            for s in stationCandidates{
                if (s.hold.remainingCapacity() - 1e-15 > self.cargo.resources.values().sum()) &&
                (s.hold.fuel > 3.0 * weight || (s.hold.gas < 2.0 && self.cargo.gas >= 2.0 && s.modules.refinery >= 1.0)){
                    station = s
                    break
                }
            }
            if station == nil{
                print("Error! no station found for refueling")
                stuck++
                return
            }
            if(distance(self.positionCartesian, station!.positionCartesian) > config.dockingRange){
                if !plotMove(to: station!.positionCartesian){
                    return
                }
            }
            if(self.cargo.remainingCapacity() < 3.001 * weight){
                self.commandQueue.append(ShipCommand.unload(station!))
            }
            self.commandQueue.append(ShipCommand.refuel(station!, targetAmount: 3.001 * weight))
        } else if self.modules.miningDrone >= 1 {
            var location = self.positionCartesian
            var roid: Asteroid? = nil
            var roids: [Asteroid] = []
            if(self.cargo.capacity == 10){
                roids = self.currentSystem.findNearbyAsteroids(to: location, findAtLeast: 50)
                roid = roids.randomElement()
                if(roid!.precious == 0 && roid!.gas == 0){
                    roid = roids.first(where: { $0.precious > 0 }) ?? roid
                }
            }
            else {
                if(random() % 10 != 0 && lastMinedLocation != nil){
                    location = lastMinedLocation!
                } else {
                    roid = self.currentSystem.findNearbyAsteroids(to: location).randomElement()
                }
            }
            if roid == nil{
                print("Error! nearest asteroid not found!")
                stuck++
                return
            }
            if distance(self.positionCartesian, roid!.positionCartesian) < config.miningRange{
                lastMinedLocation = roid!.positionCartesian
                self.commandQueue.append(ShipCommand.harvest(roid!))
            } else {
                _ = plotMove(to: roid!.positionCartesian)
                self.commandQueue.append(ShipCommand.harvest(roid!))
            }
        }     
    }

    func tick(){
        self.fuelMovingAverage = (self.fuelMovingAverage * 0.95) + self.cargo.fuel * 0.05
        if(stuck > 5){
            return
        }
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
                harvest(roid)
            case .unload(let station):
                unload(station)
            case .refuel(let station, let targetAmount):
                refuel(station, targetAmount: targetAmount)
            default:
                print("command not handled: \(action)")
            }
        }
    }
}

enum StationCommand{
    case refine(Double)
    case expandStation(Double)
    case buildShip(Double)
    case buildFactory(Double)
    case buildRefinery(Double)
    case buildStation(Double)
    case buildWeapon(Double)
    case buildDrone(Double)
}

class Station:CelestialObject{
    let hold: CargoSpace
    let modules: CargoSpace
    let system: System
    var owner: String = ""
    var commandQueue: [StationCommand] = []

    var productionCapacity: Double { get{ return self.modules.factory * config.productionRate } }

    init(seed: Int, system: System){
        self.hold = CargoSpace(capacity: config.stationDefaultCapacity)
        self.modules = CargoSpace(capacity: config.stationDefaultModuleCapacity)
        self.system = system
    }

    func proceduralInit(parent: CelestialObject){
        print("Space Station!")
        self.position = coordGen(rho_scaling: MAX_STATION_DISTANCE)
        self.position.rho += self.collisionRadius + parent.collisionRadius
        self.positionCartesian = toCartesian(self.position) + parent.positionCartesian
        self.hold.fuel = 10.0
        self.modules.refinery = 10.0
        self.modules.factory = 10.0
    }
    
    func generateCommands(){
        if(     (self.hold.remainingCapacity() < 0.2 * self.hold.capacity) ||
                (self.modules.remainingCapacity() < self.productionCapacity)){
            self.commandQueue.append(StationCommand.expandStation(self.modules.capacity))
        } else if(self.hold.fuel * 2 < self.hold.gas &&
                  self.hold.resources > config.refineryCost &&
                  self.modules.remainingCapacity() > self.productionCapacity){
            self.commandQueue.append(StationCommand.buildRefinery(self.productionCapacity))
            self.commandQueue.append(StationCommand.refine(self.modules.refinery+1))
        } else if(random() % 2 == 0 && self.hold.fuel < self.hold.gas){
            self.commandQueue.append(StationCommand.refine(min(self.hold.gas, self.modules.refinery)))
        } else if self.modules.remainingCapacity() > self.productionCapacity &&
                  self.hold.resources > config.shipCost * 5 * self.productionCapacity{
            self.commandQueue.append(StationCommand.buildFactory(self.productionCapacity))
        } else if self.hold.resources > config.shipCost * self.productionCapacity{
            self.commandQueue.append(StationCommand.buildShip(self.productionCapacity))
        }
    }

    func build(key: String, target: Double, cost:ResourceAmount){
        let maxCanBuild = (self.hold.resources / cost).values().min()!
        let willBuild = min(maxCanBuild, target, self.productionCapacity)
        if willBuild > 0{
            self.hold.resources = self.hold.resources - (cost * willBuild)
            self.hold.contents[key]! += willBuild
            self.hold.dirty = true
        }
    }

    func tick() {
        if(commandQueue.count == 0){
            self.generateCommands()
        }
        if(commandQueue.count > 0){
            let action = commandQueue[0]
            commandQueue.removeFirst()
            switch(action){
            case .refine(let target):
                let amountToRefine = min(self.modules.refinery, self.hold.gas, target)
                if(amountToRefine > 0){
                    self.hold.gas -= amountToRefine
                    self.hold.fuel += amountToRefine
                }
            case .expandStation(let target):
                let amountToExpand = min(self.modules.factory, target,
                                         (self.hold.resources / config.stationCost).values().min()!)
                if(self.hold.resources > config.stationCost * target){
                   if (target > amountToExpand){
                        self.commandQueue.append(StationCommand.expandStation(target - amountToExpand))
                        self.hold.capacity += 10 * amountToExpand
                        self.modules.capacity += amountToExpand
                        self.hold.resources = self.hold.resources - (config.stationCost * amountToExpand)
                   } else {
                        print("Station \(id) expanded to \(modules.capacity.pretty) modules capacity and \(hold.capacity.pretty) storage capacity.")
                   }
                } else {
                    // insufficient resources to expand
                }
            case .buildShip(let target):
                build(key: "spaceShip", target: target, cost:config.shipCost)
            case .buildFactory(let target):
                build(key: "factory", target: target, cost:config.factoryCost)
                if !self.hold.transfer(items: ["factory"], to:self.modules){
                    self.commandQueue.append(StationCommand.expandStation(self.modules.capacity))
                }
            case .buildRefinery(let target):
                build(key: "refinery", target: target, cost:config.refineryCost)
                if !self.hold.transfer(items: ["refinery"], to:self.modules){
                    self.commandQueue.append(StationCommand.expandStation(self.modules.capacity))
                }
            case .buildStation(let target):
                assert(false)
                
            case .buildWeapon(let target):
                assert(false)
                
            case .buildDrone(let target):
                assert(false)
                
            }
        }
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
        let multiplier = config.asteroidResourceMultiplier
        minerals *= multiplier
        gas *= multiplier
        precious *= multiplier
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

    func proceduralInit(parent: Planet, system: System){
        srandom(UInt32(self.randomSeed))
        self.collisionRadius = 1.7e3 * KM
        self.position = coordGen(rho_scaling: PLANET_RADIUS)
        self.position.rho += self.collisionRadius + parent.collisionRadius
        self.positionCartesian = toCartesian(self.position) + parent.positionCartesian
        let numStations = random() % 100 == 0 ? 1 : 0
        for _ in 0..<numStations{
            stations.append(Station(seed: random(), system:system))
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
            stations.append(Station(seed: random(), system: parent))
        }
        for i in 0..<numMoons{
            moons[i].proceduralInit(parent: self, system: parent)
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
    let randomSeed: Int
    let shipsRegistry: HctTree<Ship> = HctTree<Ship>(initialSize: SYSTEM_RADIUS, binSize: 128)
    let asteroidRegistry: HctTree<Asteroid> = HctTree<Asteroid>(initialSize: SYSTEM_RADIUS)
    var initialAsteroids: Int = 0

    var planets = [Planet]()

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
        self.initialAsteroids = numAsteroids
        var asteroids: [Asteroid] = []
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
        for i in 0..<numAsteroids{
            asteroidRegistry.insert(item: asteroids[i], position: asteroids[i].positionCartesian)
            if i % 10000 == 9999{
                print("\((100.0 * Double(i) / Double(numAsteroids)).pretty)%")
            }
        }
        print(asteroids.count)
    }
    
    func stations() -> Array<Station>{
        return planets.flatMap{ $0.stations + $0.moons.flatMap{ $0.stations } }
    }

    func findNearbyAsteroids(to: Point, findAtLeast: Int = 1) -> [Asteroid] {
        var results: [Asteroid] = []
        var range = 1e3
        while(results.count < findAtLeast && range < 2 * SYSTEM_RADIUS){
            results = asteroidRegistry.lookup(region: BBox(center: to, halfsize: range))
            range *= 2
        }
        return results
    }

    func findNearestAsteroid(to: Point) -> Asteroid? {
        var nearest: Asteroid? = nil
        let candidates = findNearbyAsteroids(to: to)
        for r in candidates {
            if nearest == nil || distance(to, r.positionCartesian) < distance(to, nearest!.positionCartesian){
                nearest = r
            }
        }
        return nearest
    }

    func nearbyStations(to: Point) -> [Station] {
        return(stations().sorted(by: { distance(to, $0.positionCartesian) < distance(to, $1.positionCartesian) } ))
    }

    func depleteAsteroid(_ roid: Asteroid) {
        self.asteroidRegistry.remove(item: roid, position: roid.positionCartesian)
    }
}

class Galaxy:CelestialObject{
    private let randomSeed: Int
    let systemsRegistry: HctTree<System> = HctTree<System>(initialSize: GALAXY_RADIUS)
    
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
    let galaxyRegistry: HctTree<Galaxy> = HctTree<Galaxy>(initialSize: UNIVERSE_RADIUS)
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

