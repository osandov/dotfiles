#ifndef NICS_H
#define NICS_H

struct net_section;
struct nic;

int enumerate_nics(struct net_section *section);
int find_wifi_nics(struct net_section *section);
int get_wifi_info(struct net_section *section, struct nic *nic);

#endif /* NICS_H */
