---
layout: post
title:  Semiconductors - general info
date: 2023-11-03 21:16:00 +0100
categories: cheatsheet
tags: semiconductors
hidden: true
---
<script src="https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML" type="text/javascript"></script>

Semiconductor is a material with variable electrical conductivity.

## Energy bands

Atoms have *energy bands* in which electrons can exist. There are:
* **valence band** - highest energy band of electrons *bound* to crystal lattice
* **conduction band** - electrons are shared by the whole crystal and can move *freely* under the influence of electric field as a *carrier*.

The bands are separated by a *band gap* $$\Delta E$$. **In semiconductors the band gap is <~3 eV or <~5 eV** depending on source.

## Conductance mechanism of intrinsic semiconductor

1. Electron absorbs energy >$$\Delta E$$ and jumps to conduction band
2. It leaves a *hole* in valence band
3. Free electrons and holes can carry a *current* before they recombine

Concentration of carriers is proportional to temperature.

## Doping

Introduction of carefully chosen impurities allows for modulation of semiconductor's properties.

Take a tetravalent semiconductor.
* adding a **pentavalent** element (donor) makes one electron loosely bound to the lattice -> N type
* adding a **trivalent** element (acceptor) makes one hole loosely bound to the lattice -> P type

## *p-n* junction

*p-n* junction is a **boundary** between touching *n* and *p* semiconductors. On that boundary, carriers diffuse and create **potential barrier**.

### Polarization

#### Reverse bias

Connecting *p* semiconductor to minus and *n* semiconductor to plus makes electrons from *n* go towards the plus and holes from *p* towards the minus **widening the depletion region** and **raising the potential barrier**. **Current doesn't flow**.

#### Forward bias

Connecting the *p* semiconductor to plus and *n* semiconductor to minus **narrows the depletion region** and **lowers the potential barrier** allowing for the **flow of current**.
