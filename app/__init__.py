
from flask import Flask
from prometheus_flask_exporter import PrometheusMetrics
from app.routes.user_routes import user_blueprint
from app.routes.product_routes import product_blueprint

def create_app():
    app = Flask(__name__)

    # Initialize Prometheus metrics
    # This automatically creates /metrics endpoint
    metrics = PrometheusMetrics(app)

    # Track default metrics (requests, duration, etc.)
    metrics.info('microservice_app_info', 'Application info', version='1.0.0')

    # Register blueprints
    app.register_blueprint(user_blueprint)
    app.register_blueprint(product_blueprint)

    return app
