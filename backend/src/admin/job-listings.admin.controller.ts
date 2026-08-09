import { Body, Controller, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles, RolesGuard } from '../auth/roles.guard';
import { PrismaService } from '../prisma/prisma.service';
import { StorageService } from '../common/storage.service';
import { ConfirmJobListingDto } from './dto/confirm-job-listing.dto';

// Covers Internships, Placements, and Govt Jobs from one admin form,
// differentiated by `type` on the JobListing model.
@ApiTags('admin-job-listings')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('ADMIN', 'SUPER_ADMIN')
@Controller('admin/job-listings')
export class JobListingsAdminController {
  constructor(private prisma: PrismaService, private storage: StorageService) {}

  @Post('confirm')
  confirm(@Body() dto: ConfirmJobListingDto) {
    return this.prisma.jobListing.create({
      data: {
        type: dto.type as any,
        title: dto.title,
        company: dto.company,
        description: dto.description,
        applyUrl: dto.applyUrl,
        deadline: dto.deadline ? new Date(dto.deadline) : undefined,
        branch: dto.branch,
        s3Key: dto.s3Key,
        fileUrl: dto.s3Key ? dto.publicUrl || this.storage.publicUrlFor(dto.s3Key) : undefined,
      },
    });
  }
}
