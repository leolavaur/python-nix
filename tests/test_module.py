from myapp.module import list_gpus


def test_list_gpus(capfd):
    list_gpus()
    out, err = capfd.readouterr()
    assert "/physical_device:GPU:0" in out
