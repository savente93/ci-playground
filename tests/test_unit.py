from playground.math import add_one


def test_random_add_one(random_int):
    assert add_one(random_int) == 5


def test_fav_color():
    print("I like blue :)")


def test_polars():
    import polars as pl
