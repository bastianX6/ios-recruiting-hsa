class MovieListPresenter: MovieListPresenterProtocol {
    weak var view: MovieListViewProtocol?
    var interactor: MovieListInteractorProtocol?
    var router: MovieListRouterProtocol?

    convenience init(interactor: MovieListInteractorProtocol, router: MovieListRouterProtocol) {
        self.init()
        self.interactor = interactor
        self.router = router
    }

    func viewDidLoad() {
        view?.showLoading()
        interactor?.fetchMovies(page: 1, append: false)
        interactor?.fetchGenres()
        interactor?.fetchSavedMoviesIds(append: false)
    }

    func willLoadMovies(page: Int, append: Bool) {
        view?.showLoading()
        interactor?.fetchMovies(page: page, append: append)
    }

    func willLoadGenres() {
        interactor?.fetchGenres()
    }

    func didTapInMovieCell(movie: MovieModel, genres: [String], isIpad: Bool, savedAdsDelegate: MovieListSavedAdsUpdate?) {
        router?.showMovieDetail(movie: movie, genres: genres, isIpad: isIpad, savedAdsDelegate: savedAdsDelegate)
    }
}

extension MovieListPresenter: MovieListInteractorDelegate {
    func fetchMoviesSuccess(movies: [MovieModel], append: Bool) {
        view?.hideLoading()
        view?.setMovies(movies: movies, append: append)
    }

    func fetchMoviesFail(error: Error) {
        view?.hideLoading()
        router?.showErrorAlert(error: error)
    }

    func fetchGenresSuccess(genres: [GenreModel]) {
        view?.setGenres(genres: genres)
    }

    func fetchGenresFail(error: Error) {}

    func fetchSavedMoviesIdsSuccess(ids: [Int32], append: Bool) {
        view?.hideLoading()
        view?.setSavedMoviesIds(ids: ids, append: append)
    }

    func fetchSavedMoviesIdsFail(error: Error) {
        view?.hideLoading()
        router?.showErrorAlert(error: error)
    }
}
