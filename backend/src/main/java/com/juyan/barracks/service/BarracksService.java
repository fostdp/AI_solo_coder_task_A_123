package com.juyan.barracks.service;

import com.juyan.barracks.entity.Barracks;
import com.juyan.barracks.repository.BarracksRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class BarracksService {

    private final BarracksRepository barracksRepository;

    public List<Barracks> findAll() {
        return barracksRepository.findAll();
    }

    public Optional<Barracks> findById(Long id) {
        return barracksRepository.findById(id);
    }

    public Optional<Barracks> findByCode(String code) {
        return barracksRepository.findByCode(code);
    }

    public Barracks save(Barracks barracks) {
        return barracksRepository.save(barracks);
    }
}
