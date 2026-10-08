FROM ohdsi/broadsea-hades@sha256:95ade14db0acc2dd25d46e82b937399598b547fcec109e7255b61ab6ecf6868e

ARG CAPR_EXT_REF=76b958db9697f7c6e08a01458d24767bb3daddc6
ARG FE_EXT_REF=c339850bf6a4f54beec66f26cc9ad8b4fcec2468

RUN apt-get update \
 && apt-get install -y --no-install-recommends libgdal-dev libgeos-dev libproj-dev libudunits2-dev libsqlite3-dev \
 && rm -rf /var/lib/apt/lists/*

RUN Rscript -e "options(Ncpus = 2); remotes::install_github('OHDSI/CaprForExtensions', ref = '${CAPR_EXT_REF}', upgrade = 'never')"
RUN Rscript -e "options(Ncpus = 2); remotes::install_github('OHDSI/FeatureExtractionForExtensions', ref = '${FE_EXT_REF}', upgrade = 'never')"

RUN Rscript -e "options(Ncpus = 2); install.packages(c('sf', 'sandwich', 'geepack', 'glmmTMB', 'blockCV'))"

COPY . /tmp/gaiaCore
RUN R CMD INSTALL --no-docs /tmp/gaiaCore && rm -rf /tmp/gaiaCore

RUN Rscript -e "library(gaiaCore); library(CaprForExtensions); library(FeatureExtractionForExtensions); library(CohortMethod); library(sf); stopifnot(length(list.files(Sys.getenv('DATABASECONNECTOR_JAR_FOLDER'), pattern = '^postgresql')) > 0)"
