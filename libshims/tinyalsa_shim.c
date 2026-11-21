/*
 * SPDX-FileCopyrightText: The PerleOS Project
 * SPDX-License-Identifier: Apache-2.0
 *
 * mixer_update_ctls() for the stock audio module (audio.primary.sm6150), which was linked
 * against Qualcomm's libtinyalsa VNDK extension. The module calls it after the amplifier and
 * DSP firmware add mixer controls at run time. AOSP tinyalsa has no such function, so this
 * library adds it on top of the vendor libtinyalsa.
 *
 * The structures below mirror the private ones of external/tinyalsa (mixer.c, mixer_io.h)
 * and must be checked whenever that project changes.
 */

#include <errno.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/types.h>

#include <sound/asound.h>

struct pollfd;

struct mixer_ops {
    void (*close)(void *data);
    int (*get_poll_fd)(void *data, struct pollfd *pfd, int count);
    ssize_t (*read_event)(void *data, struct snd_ctl_event *ev, size_t size);
    int (*ioctl)(void *data, unsigned int cmd, ...);
};

struct mixer_ctl_group;

struct mixer_ctl {
    struct mixer_ctl_group *grp;
    struct snd_ctl_elem_info *info;
    char **ename;
    bool info_retrieved;
};

struct mixer_ctl_group {
    struct snd_ctl_elem_info *elem_info;
    struct mixer_ctl *ctl;
    unsigned int count;
    int event_cnt;

    struct mixer_ops *ops;
    void *data;
};

struct mixer {
    int fd;
    struct snd_ctl_card_info card_info;
    struct mixer_ctl_group *hw_grp;
    struct mixer_ctl_group *virt_grp;
    unsigned int total_ctl_count;
};

/*
 * Appends the hardware controls created since the mixer was opened, as Qualcomm's
 * implementation does. ALSA drivers do not remove or reorder existing controls, so new ones
 * follow the ones already known. Control pointers obtained earlier are invalidated.
 */
int mixer_update_ctls(struct mixer *mixer)
{
    struct mixer_ctl_group *grp;
    struct snd_ctl_elem_list elist;
    struct snd_ctl_elem_id *eid;
    struct snd_ctl_elem_info *info;
    struct mixer_ctl *ctl;
    unsigned int old_count, added, n;

    if (!mixer || !mixer->hw_grp)
        return 0;

    grp = mixer->hw_grp;
    old_count = grp->count;

    memset(&elist, 0, sizeof(elist));
    if (grp->ops->ioctl(grp->data, SNDRV_CTL_IOCTL_ELEM_LIST, &elist) < 0)
        return -1;
    if (elist.count <= old_count)
        return 0;

    eid = calloc(elist.count - old_count, sizeof(*eid));
    if (!eid)
        return -1;

    elist.offset = old_count;
    elist.space = elist.count - old_count;
    elist.pids = eid;
    if (grp->ops->ioctl(grp->data, SNDRV_CTL_IOCTL_ELEM_LIST, &elist) < 0)
        goto fail;
    added = elist.used;

    /* A larger control array alone is harmless if the second allocation fails. */
    ctl = realloc(grp->ctl, (old_count + added) * sizeof(*ctl));
    if (!ctl)
        goto fail;
    grp->ctl = ctl;

    info = realloc(grp->elem_info, (old_count + added) * sizeof(*info));
    if (!info)
        goto fail;
    grp->elem_info = info;

    /* elem_info may have moved: re-point the existing controls. */
    for (n = 0; n < old_count; n++)
        ctl[n].info = info + n;

    memset(info + old_count, 0, added * sizeof(*info));
    memset(ctl + old_count, 0, added * sizeof(*ctl));
    for (n = old_count; n < old_count + added; n++) {
        ctl[n].grp = grp;
        ctl[n].info = info + n;
        info[n].id.numid = eid[n - old_count].numid;
        strncpy((char *)info[n].id.name, (char *)eid[n - old_count].name,
                SNDRV_CTL_ELEM_ID_NAME_MAXLEN);
        info[n].id.name[SNDRV_CTL_ELEM_ID_NAME_MAXLEN - 1] = 0;
    }

    grp->count = old_count + added;
    mixer->total_ctl_count += added;
    free(eid);
    return 0;

fail:
    free(eid);
    return -1;
}
