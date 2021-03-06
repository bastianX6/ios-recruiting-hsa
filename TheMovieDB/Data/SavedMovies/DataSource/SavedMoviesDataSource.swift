import CoreData
import Foundation
import RxSwift

protocol SavedMoviesDataSourceProtocol {
    func storeMovie(model: MovieModel) -> Completable
    func deleteMovie(id: Int32) -> Completable
    func getMovie(id: Int32) -> Single<SavedMovie>
    func getMovies() -> Single<[SavedMovie]>
    func getMoviesIds() -> Single<[Int32]>
}

class SavedMoviesDataSource: SavedMoviesDataSourceProtocol {
    private let persistentContainer: NSPersistentContainer
    private let entityName = "SavedMovie"

    init(persistentContainer: NSPersistentContainer) {
        self.persistentContainer = persistentContainer
    }

    func storeMovie(model: MovieModel) -> Completable {
        return Completable.create { completable in
            self.persistentContainer.performBackgroundTask { privateManagedObjectContext in
                let savedMovie = SavedMovie(context: privateManagedObjectContext)
                savedMovie.id = Int32(model.id)
                savedMovie.voteAverage = model.voteAverage
                savedMovie.title = model.title
                savedMovie.posterPath = model.posterPath
                savedMovie.genresId = model.genreIDS
                savedMovie.overview = model.overview
                savedMovie.releaseDate = model.releaseDate
                do {
                    try privateManagedObjectContext.save()
                    completable(.completed)
                } catch {
                    completable(.error(error))
                }
            }
            return Disposables.create()
        }
    }

    func deleteMovie(id: Int32) -> Completable {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = NSPredicate(format: "id == %i", id)

        return Completable.create { completable in
            self.persistentContainer.performBackgroundTask { privateManagedObjectContext in
                guard let firstResult = try? privateManagedObjectContext.fetch(fetchRequest).first, let savedMovie = firstResult as? SavedMovie else {
                    completable(.error(SavedMoviesSourceError.noResults))
                    return
                }
                do {
                    privateManagedObjectContext.delete(savedMovie)
                    try privateManagedObjectContext.save()
                    completable(.completed)
                } catch {
                    completable(.error(error))
                }
            }
            return Disposables.create()
        }
    }

    func getMovie(id: Int32) -> Single<SavedMovie> {
        let privateManagedObjectContext = persistentContainer.newBackgroundContext()
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = NSPredicate(format: "id == %i", id)

        return Single.create { single in
            let asynchronousFetchRequest = NSAsynchronousFetchRequest(fetchRequest: fetchRequest) { asynchronousFetchResult in
                guard let result = asynchronousFetchResult.finalResult as? [SavedMovie], let element = result.first else {
                    single(.error(SavedMoviesSourceError.noResults))
                    return
                }
                single(.success(element))
            }
            do {
                try privateManagedObjectContext.execute(asynchronousFetchRequest)
            } catch {
                single(.error(error))
            }
            return Disposables.create()
        }
    }

    func getMovies() -> Single<[SavedMovie]> {
        let privateManagedObjectContext = persistentContainer.newBackgroundContext()
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)

        return Single.create { single in
            let asynchronousFetchRequest = NSAsynchronousFetchRequest(fetchRequest: fetchRequest) { asynchronousFetchResult in
                guard let result = asynchronousFetchResult.finalResult as? [SavedMovie] else {
                    single(.error(SavedMoviesSourceError.noResults))
                    return
                }
                single(.success(result))
            }
            do {
                try privateManagedObjectContext.execute(asynchronousFetchRequest)
            } catch {
                single(.error(error))
            }
            return Disposables.create()
        }
    }

    func getMoviesIds() -> Single<[Int32]> {
        let result = getMovies().flatMap { (movies) -> Single<[Int32]> in
            return .just(movies.compactMap({ $0.id }))
        }
        return result
    }
}

enum SavedMoviesSourceError: Error {
    case noResults, notSafeObject
}
