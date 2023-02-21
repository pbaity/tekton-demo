#!/usr/bin/env python
# -*- coding: utf-8 -*-
from flask import Flask, render_template, make_response
import os
import socket
import random

colors = [
    "black",
    "blue",
    "brown",
    "darkgrey",
    "darkgreen",
    "darkmagenta",
    "deepskyblue",
    "dodgerblue",
    "forestgreen",
    "gold",
    "lightcoral",
    "red",
    "teal",
]

color = random.choice(colors)
hostname = socket.gethostname()

app = Flask(__name__)

@app.route("/", methods=['GET'])
def result():
    return make_response(render_template(
        './index.html',
        color=color,
        hostname=hostname,
    ))


if __name__ == "__main__":
    app.run(host='0.0.0.0', port=8080, debug=True)