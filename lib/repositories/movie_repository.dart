import '../models/movie.dart';
import 'json_repository.dart';

/// Repository for persistent storage and retrieval of [Movie] entities.
///
/// Stores movie records and individual seat matrices in `data/movies.json`.
class MovieRepository extends JsonRepository<Movie, String> {
  MovieRepository({super.filePath = 'data/movies.json'});

  @override
  String getId(Movie item) => item.id;

  @override
  Movie fromJson(Map<String, dynamic> json) => Movie.fromJson(json);

  @override
  Map<String, dynamic> toJson(Movie item) => item.toJson();

  @override
  List<Movie> getInitialSeeds() {
    return [
      Movie(
        id: 'MOV001',
        title: 'Avatar: The Way of Water',
        genre: 'Sci-Fi / Adventure',
        showtime: '14:00 PM',
        ticketPrice: 9.50,
        totalSeats: 5,
      ),
      Movie.blockbuster(
        id: 'MOV002',
        title: 'Avengers: Secret Wars',
        showtime: '19:30 PM',
      ),
      Movie.standard(
        id: 'MOV003',
        title: 'Kung Fu Panda 4',
        showtime: '11:00 AM',
      ),
    ];
  }

  /// Search movies whose title contains [query] (case-insensitive).
  List<Movie> searchByTitle(String query) {
    final lower = query.toLowerCase();
    return search((m) => m.title.toLowerCase().contains(lower));
  }

  /// Search movies by genre.
  List<Movie> searchByGenre(String genre) {
    final lower = genre.toLowerCase();
    return search((m) => m.genre.toLowerCase().contains(lower));
  }
}
