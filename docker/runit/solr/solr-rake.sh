#!/bin/sh

echo "Starting Solr in $RAILS_ENV mode..."
cd /rapidftr
bundle exec rake search:run
