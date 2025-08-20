FROM python:3.6
WORKDIR /app
COPY . /app
RUN pip install -r requirements.txt
EXPOSE 5002
CMD ["gunicorn", "--bind", "0.0.0.0:5002", "app:app"]
