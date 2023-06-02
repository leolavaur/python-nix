import sys

import tensorflow as tf

keras = tf.keras


def main():
    if len(sys.argv) > 1:
        try:
            seed = int(sys.argv[1])
        except ValueError:
            print("Seed must be an integer")
            sys.exit(1)
        else:
            print("Using seed: {}".format(seed))

            tf.keras.utils.set_random_seed(
                seed
            )  # sets seeds for base-python, numpy and tf
            tf.config.experimental.enable_op_determinism()

    cifar = tf.keras.datasets.cifar100
    (x_train, y_train), (x_test, y_test) = cifar.load_data()
    model = tf.keras.applications.ResNet50(
        include_top=True,
        weights=None,  # type: ignore
        input_shape=(32, 32, 3),
        classes=100,
    )

    loss_fn = tf.keras.losses.SparseCategoricalCrossentropy(from_logits=True)
    model.compile(optimizer="adam", loss=loss_fn, metrics=["accuracy"])
    model.fit(x_train, y_train, epochs=5, batch_size=64)
