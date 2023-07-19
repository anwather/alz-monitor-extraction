# ALZ Monitor Extraction

Policies from the [alz-monitor](https://github.com/Azure/alz-monitor) project extracted for use in [EPAC](https://aka.ms/epac).

## Usage

- Copy the files from the ```Definitions``` folder to your own EPAC repo.
- Adjust the following fields in the assignment files to suit your environment.
    - ```scope```
    - ```managedIdentityLocations```
    - ```parameters```

## Caveats

- Policies are untested - for issues with the policies or assignments please refer to the original [project](https://github.com/Azure/alz-monitor).
- Eventually these policies will be integrated into the ALZ project and this repo will no longer be maintained.
- The assignment files assumes an ALZ recommended management group structure - as described in [this link](https://github.com/Azure/alz-monitor/wiki/Introduction-to-deploying-ALZ-Monitor#determining-your-management-group-hierarchy).
