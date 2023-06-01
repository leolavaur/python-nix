from myapp.module import do_something


def test_do_something(capfd):
    do_something()
    out, err = capfd.readouterr()
    assert "Done!" in out
