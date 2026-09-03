import CoreLocation
import Foundation
import MapKit

enum RouteBuilder {
    static func roadRoute(
        from start: CLLocationCoordinate2D,
        to end: CLLocationCoordinate2D,
        mode: TravelMode
    ) async throws -> [CLLocationCoordinate2D] {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: end))
        request.transportType = mode.mkTransportType
        request.requestsAlternateRoutes = false

        let directions = MKDirections(request: request)
        let response = try await directions.calculate()
        guard let route = response.routes.first else {
            throw NSError(domain: "Locus", code: 1, userInfo: [NSLocalizedDescriptionKey: "No route found"])
        }
        return sample(polyline: route.polyline, every: 12)
    }

    static func sample(polyline: MKPolyline, every meters: CLLocationDistance) -> [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](repeating: .init(), count: polyline.pointCount)
        polyline.getCoordinates(&coords, range: NSRange(location: 0, length: polyline.pointCount))
        return sample(coordinates: coords, every: meters)
    }

    static func sample(coordinates: [CLLocationCoordinate2D], every meters: CLLocationDistance) -> [CLLocationCoordinate2D] {
        guard coordinates.count > 1 else { return coordinates }
        var sampled = [coordinates[0]]
        for (a, b) in zip(coordinates, coordinates.dropFirst()) {
            let dist = CLLocation(latitude: a.latitude, longitude: a.longitude)
                .distance(from: CLLocation(latitude: b.latitude, longitude: b.longitude))
            let steps = max(1, Int(ceil(dist / meters)))
            for i in 1...steps {
                let t = Double(i) / Double(steps)
                sampled.append(CLLocationCoordinate2D(
                    latitude: a.latitude + (b.latitude - a.latitude) * t,
                    longitude: a.longitude + (b.longitude - a.longitude) * t
                ))
            }
        }
        return sampled
    }
}

enum GPXCodec {
    static func parse(_ url: URL) throws -> [CLLocationCoordinate2D] {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        let data = try Data(contentsOf: url)
        let delegate = GPXParserDelegate()
        let parser = XMLParser(data: data)
        parser.shouldProcessNamespaces = true
        parser.delegate = delegate
        let success = parser.parse()
        if let error = delegate.fatalError {
            throw error
        }
        if !success, let parserError = parser.parserError {
            throw NSError(domain: "Locus", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "GPX file is malformed: \(parserError.localizedDescription)"])
        }
        guard !delegate.coords.isEmpty else {
            throw NSError(domain: "Locus", code: 2, userInfo: [NSLocalizedDescriptionKey: "No track points found in GPX"])
        }
        return delegate.coords
    }

    static func export(_ coordinates: [CLLocationCoordinate2D], name: String = "Locus Route") -> String {
        var body = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="Locus" xmlns="http://www.topografix.com/GPX/1/1">
          <trk>
            <name>\(name)</name>
            <trkseg>

        """
        for c in coordinates {
            body += String(format: "      <trkpt lat=\"%.6f\" lon=\"%.6f\"></trkpt>\n", c.latitude, c.longitude)
        }
        body += """
            </trkseg>
          </trk>
        </gpx>
        """
        return body
    }
}

private final class GPXParserDelegate: NSObject, XMLParserDelegate {
    var coords: [CLLocationCoordinate2D] = []
    var fatalError: Error?

    private let pointElements: Set<String> = ["trkpt", "rtept"]

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                qualifiedName: String?, attributes: [String: String]) {
        guard pointElements.contains(elementName),
              let latStr = attributes["lat"], let lat = Double(latStr),
              let lonStr = attributes["lon"], let lon = Double(lonStr),
              CLLocationCoordinate2DIsValid(CLLocationCoordinate2D(latitude: lat, longitude: lon)) else { return }
        coords.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        fatalError = NSError(domain: "Locus", code: 2,
                            userInfo: [NSLocalizedDescriptionKey: "GPX file is malformed: \(parseError.localizedDescription)"])
    }
}
