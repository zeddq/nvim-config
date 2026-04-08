"""Example module for LSP and DAP demo recordings."""

from dataclasses import dataclass


@dataclass
class Vector:
    """A 2D vector with basic arithmetic operations."""

    x: float
    y: float

    def magnitude(self) -> float:
        """Return the Euclidean length of the vector."""
        return (self.x**2 + self.y**2) ** 0.5

    def normalized(self) -> "Vector":
        """Return a unit vector in the same direction."""
        mag = self.magnitude()
        if mag == 0:
            raise ValueError("Cannot normalize a zero vector")
        return Vector(self.x / mag, self.y / mag)

    def dot(self, other: "Vector") -> float:
        """Compute the dot product with another vector."""
        return self.x * other.x + self.y * other.y

    def __add__(self, other: "Vector") -> "Vector":
        return Vector(self.x + other.x, self.y + other.y)

    def __repr__(self) -> str:
        return f"Vector({self.x}, {self.y})"


def compute_distance(a: Vector, b: Vector) -> float:
    """Return the Euclidean distance between two vectors."""
    dx = a.x - b.x
    dy = a.y - b.y
    return (dx**2 + dy**2) ** 0.5


def find_closest(target: Vector, candidates: list[Vector]) -> Vector | None:
    """Find the candidate vector closest to the target.

    Returns None if candidates is empty.
    """
    if not candidates:
        return None

    closest = candidates[0]
    best_dist = compute_distance(target, closest)

    for candidate in candidates[1:]:
        dist = compute_distance(target, candidate)
        if dist < best_dist:
            best_dist = dist
            closest = candidate

    return closest


def main() -> None:
    """Run a quick demo of vector operations."""
    origin = Vector(0, 0)
    points = [
        Vector(3, 4),
        Vector(1, 1),
        Vector(6, 8),
        Vector(2, 7),
    ]

    for point in points:
        distance = compute_distance(origin, point)
        print(f"{point} is {distance:.2f} from origin")

    nearest = find_closest(origin, points)
    print(f"Closest to origin: {nearest}")

    if nearest is not None:
        unit = nearest.normalized()
        print(f"Unit vector: {unit}")


if __name__ == "__main__":
    main()
