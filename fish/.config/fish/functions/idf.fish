function idf --description "Activate the ESP-IDF 6.1 environment"
    source $HOME/.espressif/tools/activate_idf_v6.1.fish
    and set -gx ESP_IDF_VERSION 6.1.0
end
