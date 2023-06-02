import tensorflow as tf


def list_gpus():
    gpus = tf.config.list_physical_devices("GPU")
    for gpu in gpus:
        print("Name:", gpu.name, "Type:", gpu.device_type)
