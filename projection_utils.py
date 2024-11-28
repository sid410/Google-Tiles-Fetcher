import math
import mathutils


class TransverseMercator:
    """
    A utility class for Transverse Mercator projection calculations.
    """
    radius = 6378137.0  # Earth's radius in meters

    def __init__(self, lat=0.0, lon=0.0, k=1.0):
        self.lat = lat
        self.lon = lon
        self.k = k
        self.latInRadians = math.radians(lat)

    def fromGeographic(self, lat, lon):
        """
        Converts geographic coordinates (lat, lon) to Transverse Mercator (x, y).
        """
        lat = math.radians(lat)
        lon = math.radians(lon - self.lon)
        B = math.sin(lon) * math.cos(lat)
        x = 0.5 * self.k * self.radius * math.log((1.0 + B) / (1.0 - B))
        y = self.k * self.radius * (math.atan(math.tan(lat) / math.cos(lon)) - self.latInRadians)
        return (x, y)

    def toGeographic(self, x, y):
        """
        Converts Transverse Mercator coordinates (x, y) to geographic (lat, lon).
        """
        x = x / (self.k * self.radius)
        y = y / (self.k * self.radius)
        D = y + self.latInRadians
        lon = math.atan(math.sinh(x) / math.cos(D))
        lat = math.asin(math.sin(D) / math.cosh(x))

        lon = self.lon + math.degrees(lon)
        lat = math.degrees(lat)
        return (lat, lon)


def calculate_real_bounds(obj, projection):
    """
    Calculate the real latitude and longitude bounds of an object using the Transverse Mercator projection.
    """
    
    min_bound = [min(v[i] for v in obj.bound_box) for i in range(3)]
    max_bound = [max(v[i] for v in obj.bound_box) for i in range(3)]

    # Apply world transformation
    min_bound_world = obj.matrix_world @ mathutils.Vector(min_bound)
    max_bound_world = obj.matrix_world @ mathutils.Vector(max_bound)

    real_min_lat, real_min_lon = projection.toGeographic(min_bound_world.x, min_bound_world.y)
    real_max_lat, real_max_lon = projection.toGeographic(max_bound_world.x, max_bound_world.y)

    return real_min_lat, real_min_lon, real_max_lat, real_max_lon
